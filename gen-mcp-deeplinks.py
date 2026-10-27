#!/usr/bin/env python3
"""
Generate Goose extension deeplinks from MCP servers in the official MCP registry.

Fetches servers from https://registry.modelcontextprotocol.io/v0.1/servers,
filters for stdio-based packages and streamable-http remotes, and generates
goose://extension deeplinks.

Goose deeplink format (validated against goose-docs.ai/deeplink-generator):

  Stdio package:
    goose://extension?cmd=<command>&arg=<arg1>&arg=<arg2>&id=<id>&name=<name>&description=<description>

  Streamable-http remote:
    goose://extension?type=streamable_http&url=<url>&id=<id>&name=<name>&description=<description>
      [&env=<name>=<desc>...] [&header=<name>=<desc>...]

Where cmd must be one of: cu, docker, jbang, npx, uvx, goose, npx.cmd

Registry type → Goose command mapping:
    npm   → npx  with args: -y <identifier>
    pypi  → uvx  with args: <identifier>
    docker→ docker with args: run <identifier>
    oci   → docker with args: run <identifier>

Usage:
    python3 gen-mcp-deeplinks.py [limit] [format] [max_pages]
    limit   - Max servers to fetch per page (default: 100)
    format  - markdown | json | links (default: markdown)
    max_pages - Max pages to fetch (default: 10)

    Also supports --dedupe to keep only the latest version per server+package.
"""

import json
import urllib.parse
import urllib.request
import sys

REGISTRY_BASE = "https://registry.modelcontextprotocol.io/v0.1/servers"
MAX_PAGES = 10  # Safety limit to avoid infinite pagination

# Allowed Goose commands (from goose-docs.ai/deeplink-generator)
GOOSE_ALLOWED_CMDS = {"cu", "docker", "jbang", "npx", "uvx", "goose", "npx.cmd"}

# MCP registryType → (Goose cmd, runtime args prefix)
REGISTRY_TYPE_MAP = {
    "npm": ("npx", ["-y"]),
    "pypi": ("uvx", []),
    "docker": ("docker", ["run"]),
    "oci": ("docker", ["run"]),
}


def fetch_servers(limit=100, max_pages=MAX_PAGES):
    """Fetch servers from the MCP registry with pagination."""
    servers = []
    cursor = None
    pages = 0

    while pages < max_pages:
        pages += 1
        url = REGISTRY_BASE
        params = []
        if cursor:
            params.append(f"cursor={urllib.parse.quote(cursor)}")
        params.append(f"limit={limit}")
        url += "?" + "&".join(params)

        try:
            req = urllib.request.Request(url, headers={"User-Agent": "goose-deeplink-generator/1.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
        except Exception as e:
            print(f"Error fetching page {pages}: {e}", file=sys.stderr)
            break

        batch = data.get("servers", [])
        servers.extend(batch)

        meta = data.get("metadata", {})
        cursor = meta.get("nextCursor")
        if not cursor or not batch:
            break

    return servers


def package_to_goose_cmd(pkg):
    """
    Convert an MCP registry package to (cmd, [args]) for Goose deeplink.
    Returns None if the package type is not supported.
    """
    reg_type = pkg.get("registryType")
    if reg_type not in REGISTRY_TYPE_MAP:
        return None

    cmd, prefix_args = REGISTRY_TYPE_MAP[reg_type]
    identifier = pkg.get("identifier", "")
    args = list(prefix_args) + [identifier]
    return cmd, args


def server_to_deeplinks(server_entry):
    """
    Convert an MCP registry server entry to a list of Goose deeplinks.
    Generates one deeplink per runnable stdio package, plus one per
    streamable-http remote.
    """
    svr = server_entry.get("server", {})
    name = svr.get("name", "")
    title = svr.get("title", "") or name.split("/")[-1]
    description = svr.get("description", "")
    pkgs = svr.get("packages") or []
    remotes = svr.get("remotes") or []

    deeplinks = []

    # --- 1) stdio package ---------------------------------------------------
    for pkg in pkgs:
        # Only stdio transport can be run as a local command
        transport = pkg.get("transport", {})
        if transport.get("type") != "stdio":
            continue

        result = package_to_goose_cmd(pkg)
        if result is None:
            continue

        cmd, args = result

        # Validate cmd is in Goose's allowed list
        if cmd not in GOOSE_ALLOWED_CMDS:
            continue

        # Build query parameters
        params = [
            ("cmd", cmd),
            ("id", name),
            ("name", title),
            ("description", description),
        ]

        # Add environment variables as env=KEY=VALUE
        env_vars = pkg.get("environmentVariables") or []
        for env in env_vars:
            env_name = env.get("name", "")
            env_desc = env.get("description", "")
            if env_name:
                params.append(("env", f"{env_name}={env_desc}"))

        # Add runtime arguments
        for arg in args:
            params.append(("arg", arg))

        # Build query string
        query = "&".join(f"{k}={urllib.parse.quote(str(v), safe='')}" for k, v in params)
        deeplink = f"goose://extension?{query}"
        deeplinks.append({
            "name": name,
            "title": title,
            "description": description,
            "cmd": cmd,
            "args": args,
            "type": "stdio",
            "deeplink": deeplink,
            "registryType": pkg.get("registryType"),
            "identifier": pkg.get("identifier", ""),
        })

    # --- 2) streamable-http remote ------------------------------------------
    for rem in remotes:
        if not rem or rem.get("type") != "streamable-http" or not rem.get("url"):
            continue

        params = [
            ("type", "streamable_http"),
            ("url", rem.get("url", "")),
            ("id", name),
            ("name", title),
            ("description", description),
        ]

        # Environment variables (per-remote, fallback to server-level)
        env_vars = rem.get("environmentVariables") or svr.get("environmentVariables") or []
        for env in env_vars:
            env_name = env.get("name", "")
            env_desc = env.get("description", "")
            if env_name:
                params.append(("env", f"{env_name}={env_desc}"))

        # Request headers
        headers = rem.get("headers") or []
        for header in headers:
            h_name = header.get("name", "")
            h_desc = header.get("description", "")
            if h_name:
                params.append(("header", f"{h_name}={h_desc}"))

        # Build query string
        query = "&".join(f"{k}={urllib.parse.quote(str(v), safe='')}" for k, v in params)
        deeplink = f"goose://extension?{query}"
        deeplinks.append({
            "name": name,
            "title": title,
            "description": description,
            "type": "streamable_http",
            "url": rem.get("url", ""),
            "registryType": "remote",
            "identifier": rem.get("url", ""),
            "deeplink": deeplink,
        })

    return deeplinks


def main():
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    output_format = sys.argv[2] if len(sys.argv) > 2 else "markdown"
    max_pages = int(sys.argv[3]) if len(sys.argv) > 3 else MAX_PAGES
    dedupe = "--dedupe" in sys.argv

    print(f"Fetching MCP servers from {REGISTRY_BASE}...", file=sys.stderr)
    servers = fetch_servers(limit=limit, max_pages=max_pages)
    print(f"Fetched {len(servers)} server entries ({max_pages} pages max).", file=sys.stderr)

    all_deeplinks = []
    for entry in servers:
        deeplinks = server_to_deeplinks(entry)
        all_deeplinks.extend(deeplinks)

    # Deduplicate by server name + package/remote identifier (keep first/latest)
    if dedupe:
        seen = set()
        deduped = []
        for d in all_deeplinks:
            key = (d["name"], d["identifier"])
            if key not in seen:
                seen.add(key)
                deduped.append(d)
        all_deeplinks = deduped

    print(f"Generated {len(all_deeplinks)} Goose deeplinks.", file=sys.stderr)

    if output_format == "markdown":
        print("\n# MCP Servers → Goose Deeplinks\n")
        print("Generated from https://registry.modelcontextprotocol.io\n")
        print("| Server | Type | Package/Remote | Goose Command | Deeplink |")
        print("|--------|------|----------------|--------------|----------|")
        for d in all_deeplinks:
            if d["type"] == "stdio":
                cmd_str = f"`{d['cmd']} {' '.join(d['args'])}`"
                pkg_col = d["identifier"]
            else:
                cmd_str = "`streamable_http`"
                pkg_col = d["url"]
            link_text = f"[Install]({d['deeplink']})"
            print(f"| {d['title']} | {d['type']} | {pkg_col} | {cmd_str} | {link_text} |")

    elif output_format == "json":
        print(json.dumps(all_deeplinks, indent=2))

    elif output_format == "links":
        for d in all_deeplinks:
            print(d["deeplink"])


if __name__ == "__main__":
    main()