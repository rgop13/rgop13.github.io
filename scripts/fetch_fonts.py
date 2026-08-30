#!/usr/bin/env python3
"""Download latin woff2 subsets from the Google Fonts CSS API, deduplicating
variable-font files that serve multiple weights from one URL."""
import hashlib, re, urllib.request, pathlib

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
CSS_URL = ("https://fonts.googleapis.com/css2?"
           "family=STIX+Two+Text:ital,wght@0,400;0,600;0,700;1,400"
           "&family=IBM+Plex+Sans:wght@400;500;600"
           "&family=IBM+Plex+Mono:wght@400;600&display=swap")
NAME = {"STIX Two Text": "stix-two-text", "IBM Plex Sans": "ibm-plex-sans",
        "IBM Plex Mono": "ibm-plex-mono"}
EXPECTED = {"stix-two-text-var.woff2", "stix-two-text-400i.woff2",
            "ibm-plex-sans-var.woff2",
            "ibm-plex-mono-400.woff2", "ibm-plex-mono-600.woff2"}
OUT = pathlib.Path("assets/webfonts")
OUT.mkdir(parents=True, exist_ok=True)

def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    return urllib.request.urlopen(req).read()

css = fetch(CSS_URL).decode()
blocks = re.findall(r"/\*\s*(\S+)\s*\*/\s*@font-face\s*\{(.*?)\}", css, re.S)
groups = {}
for subset, body in blocks:
    if subset != "latin":
        continue
    family = re.search(r"font-family:\s*'([^']+)'", body).group(1)
    style = re.search(r"font-style:\s*(\w+)", body).group(1)
    weight = re.search(r"font-weight:\s*(\d+)", body).group(1)
    url = re.search(r"url\((\S+?\.woff2)\)", body).group(1)
    groups.setdefault((family, style), {}).setdefault(url, []).append(weight)

saved = {}
for (family, style), urls in groups.items():
    for url, weights in urls.items():
        if len(weights) > 1:
            fname = f"{NAME[family]}-var.woff2"
        else:
            fname = f"{NAME[family]}-{weights[0]}{'i' if style == 'italic' else ''}.woff2"
        data = fetch(url)
        (OUT / fname).write_bytes(data)
        saved[fname] = data

for fname in sorted(saved):
    print(f"{fname}  {len(saved[fname])/1024:.0f} KB")
assert set(saved) == EXPECTED, f"unexpected file set: {sorted(saved)}"
digests = {hashlib.sha256(d).hexdigest() for d in saved.values()}
assert len(digests) == len(saved), "duplicate file contents detected"
total = sum(len(d) for d in saved.values())
print(f"total {total/1024:.0f} KB")
assert total < 220 * 1024, f"over 220KB budget: {total}"
print(f"PASS: {len(saved)} unique latin woff2 files saved")
