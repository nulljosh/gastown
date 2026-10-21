# Raw App Store Connect screenshot upload: reserve, PUT parts, commit with MD5, poll.
import json, subprocess, sys, hashlib, os, time, urllib.request
def api(method, path, body=None):
    cmd = ["asc", "api", method, path]
    if body is not None: cmd += ["--confirm", "--body", json.dumps(body)]
    elif method != "GET": cmd += ["--confirm"]
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode: sys.exit(f"{method} {path} failed: {out.stderr or out.stdout}")
    return json.loads(out.stdout) if out.stdout.strip() else {}
set_id, path = sys.argv[1], sys.argv[2]
data = open(path, "rb").read()
r = api("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots",
    "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
    "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
sid, ops = r["data"]["id"], r["data"]["attributes"]["uploadOperations"]
print("reserved", sid, "parts", len(ops))
for op in ops:
    chunk = data[op["offset"]:op["offset"] + op["length"]]
    req = urllib.request.Request(op["url"], data=chunk, method=op["method"])
    for h in op.get("requestHeaders", []): req.add_header(h["name"], h["value"])
    print("part", op["offset"], op["length"], urllib.request.urlopen(req).status)
api("PATCH", f"/v1/appScreenshots/{sid}", {"data": {"type": "appScreenshots", "id": sid,
    "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
for _ in range(120):
    st = api("GET", f"/v1/appScreenshots/{sid}")["data"]["attributes"]["assetDeliveryState"]
    if st["state"] in ("COMPLETE", "FAILED"): break
    time.sleep(5)
print(os.path.basename(path), json.dumps(st))
