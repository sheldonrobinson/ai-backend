/**
 * Goose MCP Deeplink Generator (JavaScript)
 *
 * Fetches MCP server info from the official registry and generates
 * goose://extension deeplinks for stdio-based packages.
 *
 * Goose deeplink format (per goose-docs.ai/deeplink-generator):
 *   goose://extension?cmd=<command>&arg=<arg1>&arg=<arg2>&id=<id>&name=<name>&description=<description>
 *
 * Allowed cmd values: cu, docker, jbang, npx, uvx, goose, npx.cmd
 */

const REGISTRY_BASE = "https://registry.modelcontextprotocol.io/v0.1/servers";

const GOOSE_ALLOWED_CMDS = new Set([
  "cu", "docker", "jbang", "npx", "uvx", "goose", "npx.cmd",
]);

const REGISTRY_TYPE_MAP = {
  npm: { cmd: "npx", prefixArgs: ["-y"] },
  pypi: { cmd: "uvx", prefixArgs: [] },
  docker: { cmd: "docker", prefixArgs: ["run"] },
  oci: { cmd: "docker", prefixArgs: ["run"] },
};

/**
 * Fetch all servers from the MCP registry with pagination.
 * @param {number} limit - Max servers per page
 * @param {number} maxPages - Safety limit for pages
 * @returns {Promise<Array>} Array of server entries
 */
async function fetchServers(limit = 100, maxPages = 10) {
  const servers = [];
  let cursor = null;
  let pages = 0;

  while (pages < maxPages) {
    pages++;
    const params = new URLSearchParams({ limit: String(limit) });
    if (cursor) params.set("cursor", cursor);

    const url = `${REGISTRY_BASE}?${params.toString()}`;

    try {
      const response = await fetch(url, {
        headers: { "User-Agent": "goose-mcp-deeplink-generator/1.0" },
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const data = await response.json();
      const batch = data.servers || [];
      servers.push(...batch);

      cursor = data.metadata?.nextCursor;
      if (!cursor || !batch.length) break;
    } catch (err) {
      console.error(`Error fetching page ${pages}:`, err);
      break;
    }
  }

  return servers;
}

/**
 * Convert an MCP registry package to (cmd, args) for Goose.
 * @param {Object} pkg - Package object from registry
 * @returns {Object|null} { cmd, args } or null if unsupported
 */
function packageToGooseCmd(pkg) {
  const mapping = REGISTRY_TYPE_MAP[pkg.registryType];
  if (!mapping) return null;

  const identifier = pkg.identifier || "";
  const args = [...mapping.prefixArgs, identifier];
  return { cmd: mapping.cmd, args };
}

/**
 * Generate Goose deeplinks for a single server entry.
 * @param {Object} entry - Server entry from registry
 * @returns {Array<Object>} Array of { name, title, description, cmd, args, deeplink, registryType, identifier }
 */
function serverToDeeplinks(entry) {
  const svr = entry.server || {};
  const name = svr.name || "";
  const title = svr.title || name.split("/").pop() || "";
  const description = svr.description || "";
  const pkgs = svr.packages || [];

  const deeplinks = [];

  for (const pkg of pkgs) {
    // Only stdio transport can run as a local command
    const transport = pkg.transport || {};
    if (transport.type !== "stdio") continue;

    const result = packageToGooseCmd(pkg);
    if (!result) continue;

    const { cmd, args } = result;

    // Validate cmd is in Goose's allowed list
    if (!GOOSE_ALLOWED_CMDS.has(cmd)) continue;

    // Build query parameters
    const params = [
      ["cmd", cmd],
      ["id", name],
      ["name", title],
      ["description", description],
    ];

    // Add environment variables as env=KEY=VALUE
    const envVars = pkg.environmentVariables || [];
    for (const env of envVars) {
      const envName = env.name || "";
      const envDesc = env.description || "";
      if (envName) {
        params.push(["env", `${envName}=${envDesc}`]);
      }
    }

    // Add runtime arguments
    for (const arg of args) {
      params.push(["arg", arg]);
    }

    const query = params
      .map(([k, v]) => `${k}=${encodeURIComponent(String(v))}`)
      .join("&");

    deeplinks.push({
      name,
      title,
      description,
      cmd,
      args,
      deeplink: `goose://extension?${query}`,
      registryType: pkg.registryType,
      identifier: pkg.identifier || "",
    });
  }

  return deeplinks;
}

/**
 * Look up a server by name from the MCP registry and generate Goose deeplinks.
 * @param {string} serverName - Server name to search for (e.g. "agency.kesey/pretrip" or "pretrip")
 * @param {Object} options - { limit, maxPages, dedupe, fuzzy }
 * @returns {Promise<Array>} Array of deeplink objects
 */
async function lookupServer(serverName, options = {}) {
  const {
    limit = 100,
    maxPages = 10,
    dedupe = true,
    fuzzy = true,
  } = options;

  const servers = await fetchServers(limit, maxPages);
  const nameLower = serverName.toLowerCase();

  const matches = servers.filter((entry) => {
    const svr = entry.server || {};
    const name = svr.name || "";
    const title = svr.title || "";
    if (fuzzy) {
      return name.toLowerCase().includes(nameLower) ||
             title.toLowerCase().includes(nameLower);
    }
    return name === serverName || title === serverName;
  });

  const allDeeplinks = [];
  for (const entry of matches) {
    allDeeplinks.push(...serverToDeeplinks(entry));
  }

  if (dedupe) {
    const seen = new Set();
    const deduped = [];
    for (const d of allDeeplinks) {
      const key = `${d.name}|${d.identifier}`;
      if (!seen.has(key)) {
        seen.add(key);
        deduped.push(d);
      }
    }
    return deduped;
  }

  return allDeeplinks;
}

/**
 * Generate a Goose deeplink URL from parameters.
 * @param {Object} params - { cmd, args, id, name, description, envVars }
 * @returns {string} goose://extension deeplink
 */
function buildDeeplink({ cmd, args = [], id = "", name = "", description = "", envVars = [] }) {
  const params = [
    ["cmd", cmd],
    ["id", id],
    ["name", name],
    ["description", description],
  ];

  for (const env of envVars) {
    if (env.key) {
      params.push(["env", `${env.key}=${env.value || ""}`]);
    }
  }

  for (const arg of args) {
    params.push(["arg", arg]);
  }

  return `goose://extension?${params
    .map(([k, v]) => `${k}=${encodeURIComponent(String(v))}`)
    .join("&")}`;
}

// Export for Node.js / bundler usage
if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    fetchServers,
    packageToGooseCmd,
    serverToDeeplinks,
    lookupServer,
    buildDeeplink,
    REGISTRY_TYPE_MAP,
    GOOSE_ALLOWED_CMDS,
  };
}