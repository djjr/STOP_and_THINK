#!/usr/bin/env python3
"""
server.py — Stop+Think local editor server

Run via start.command, or directly:
    python3 server.py
    open http://localhost:5742
"""
from flask import Flask, jsonify, request, send_from_directory
from pathlib import Path
import os
import subprocess
import tempfile

app = Flask(__name__)

HERE        = Path(__file__).parent
STDATA      = HERE / "stdata.js"
SSH_KEY     = Path.home() / ".ssh" / "id_ed25519"
SFTP_USER   = "danryane"
SFTP_HOST   = "innoeduvation.org"
REMOTE_PATH = "/home/danryane/public_html/danryan/production/teaching/stop_and_think/stdata.js"


@app.route("/")
def index():
    return send_from_directory(HERE, "editor.html")


@app.route("/<path:filename>")
def static_files(filename):
    return send_from_directory(HERE, filename)


@app.route("/api/save", methods=["POST"])
def api_save():
    data = request.get_data(as_text=True)
    if not data:
        return jsonify({"ok": False, "error": "Empty body"}), 400
    STDATA.write_text(data, encoding="utf-8")
    return jsonify({"ok": True})


@app.route("/api/deploy", methods=["POST"])
def api_deploy():
    data = request.get_data(as_text=True)
    if not data:
        return jsonify({"ok": False, "error": "Empty body"}), 400

    # Save to disk first
    STDATA.write_text(data, encoding="utf-8")

    # Write sftp batch commands to a temp file
    with tempfile.NamedTemporaryFile(mode="w", suffix=".sftp", delete=False) as f:
        f.write(f'put "{STDATA}" "{REMOTE_PATH}"\nbye\n')
        batch = f.name

    try:
        result = subprocess.run(
            ["sftp",
             "-i", str(SSH_KEY),
             "-o", f"User={SFTP_USER}",
             "-o", "StrictHostKeyChecking=accept-new",
             "-b", batch,
             SFTP_HOST],
            capture_output=True,
            text=True,
            timeout=30,
        )
    finally:
        os.unlink(batch)

    if result.returncode == 0:
        return jsonify({"ok": True, "output": result.stdout})
    else:
        return jsonify({"ok": False, "error": result.stderr or result.stdout})


if __name__ == "__main__":
    print(f"\n  Stop+Think Editor → http://localhost:5742\n")
    app.run(port=5742, debug=False)
