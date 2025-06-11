#!/usr/bin/env python3
import json
from pathlib import Path

def main() -> None:
    cfg = json.loads(Path("template.json").read_text(encoding="utf-8"))
    src = json.loads(Path("input.json").read_text(encoding="utf-8"))

    outbounds = []

    for ob in src.get("outbounds", []):
        if ob.get("protocol") != "vless":
            continue

        vnext = ob["settings"]["vnext"][0]
        user = vnext["users"][0]
        rs = ob["streamSettings"]["realitySettings"]

        outbounds.append(
            {
                "type": "vless",
                "tag": "proxy",
                "server": vnext["address"],
                "server_port": vnext["port"],
                "uuid": user["id"],
                "flow": user.get("flow", ""),
                "packet_encoding": "xudp",
                "tls": {
                    "enabled": True,
                    "server_name": rs["serverName"],
                    "utls": {
                        "enabled": True,
                        "fingerprint": rs["fingerprint"],
                    },
                    "reality": {
                        "enabled": True,
                        "public_key": rs["publicKey"],
                        "short_id": rs["shortId"],
                    },
                },
            }
        )

    outbounds.append({"type": "direct", "tag": "direct"})
    cfg["outbounds"] = outbounds

    Path("sing-config.json").write_text(json.dumps(cfg, indent=2, ensure_ascii=False))
    print("/app/sing-config.json generated")

if __name__ == "__main__":
    main()
