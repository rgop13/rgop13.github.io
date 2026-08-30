#!/usr/bin/env python3
"""Download latin woff2 subsets from the Google Fonts CSS API."""
import re, urllib.request, pathlib

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
CSS_URL = ("https://fonts.googleapis.com/css2?"
           "family=STIX+Two+Text:ital,wght@0,400;0,600;0,700;1,400"
           "&family=IBM+Plex+Sans:wght@400;500;600"
           "&family=IBM+Plex+Mono:wght@400;600&display=swap")
NAME = {"STIX Two Text": "stix-two-text", "IBM Plex Sans": "ibm-plex-sans",
        "IBM Plex Mono": "ibm-plex-mono"}
OUT = pathlib.Path("assets/webfonts")
OUT.mkdir(parents=True, exist_ok=True)

req = urllib.request.Request(CSS_URL, headers={"User-Agent": UA})
css = urllib.request.urlopen(req).read().decode()
blocks = re.findall(r"/\*\s*(\S+)\s*\*/\s*@font-face\s*\{(.*?)\}", css, re.S)
saved = []
for subset, body in blocks:
    if subset != "latin":
        continue
    family = re.search(r"font-family:\s*'([^']+)'", body).group(1)
    style = re.search(r"font-style:\s*(\w+)", body).group(1)
    weight = re.search(r"font-weight:\s*(\d+)", body).group(1)
    url = re.search(r"url\((\S+?\.woff2)\)", body).group(1)
    fname = f"{NAME[family]}-{weight}{'i' if style == 'italic' else ''}.woff2"
    data = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA})).read()
    (OUT / fname).write_bytes(data)
    saved.append((fname, len(data)))
for fname, size in sorted(saved):
    print(f"{fname}  {size/1024:.0f} KB")
assert len(saved) == 9, f"expected 9 latin files, got {len(saved)}"
print("PASS: 9 latin woff2 files saved")
