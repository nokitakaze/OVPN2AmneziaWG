#!/usr/bin/env python3
import json
import socket
import sys
from pathlib import Path

# Primary configuration path
cfg_path = Path("/app/sing-config.json")
if not cfg_path.is_file():
    sys.exit(1)

with cfg_path.open(encoding="utf-8") as f:
    cfg = json.load(f)

# Search for first outbound with type == "vless"
outbound = next(
    (o for o in cfg.get("outbounds", []) if o.get("type") == "vless"),
    None,
)
if outbound is None:
    print('Outbound с type="vless" не найден\n')
    sys.exit(1)
    raise RuntimeError()

server_host = outbound["server"]
ip_addr = socket.gethostbyname(server_host)

sys.stdout.write(ip_addr)
