"""Write the mobile client's public Supabase connection settings."""

import base64
import json
import os
import sys
from pathlib import Path
from urllib.parse import urlsplit

url = os.environ.get("MADAR_QURAN_API_URL", "")
key = os.environ.get("MADAR_SUPABASE_ANON_KEY", "")

try:
    endpoint = urlsplit(url)
    _, payload, _ = key.split(".")
    claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
    if (
        endpoint.scheme != "https"
        or endpoint.path not in ("/functions/v1/quran", "/functions/v1/quran-dev")
        or not endpoint.hostname
        or not endpoint.hostname.endswith(".supabase.co")
        or endpoint.username is not None
        or endpoint.port is not None
        or endpoint.query
        or endpoint.fragment
        or claims["role"] != "anon"
        or claims["ref"] != endpoint.hostname.removesuffix(".supabase.co")
    ):
        raise ValueError
except (AttributeError, ValueError, KeyError, TypeError):
    raise SystemExit("Configure the Quran endpoint URL and its public legacy anon key.")

Path(sys.argv[1]).write_text(
    json.dumps({"MADAR_QURAN_API_URL": url, "MADAR_SUPABASE_ANON_KEY": key}),
    encoding="utf-8",
)
