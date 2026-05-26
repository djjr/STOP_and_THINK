#!/bin/bash
cd "$(dirname "$0")"

python3 -c "import flask" 2>/dev/null || pip3 install flask

# Kill any previous instance on this port
lsof -ti:5742 | xargs kill -9 2>/dev/null

python3 server.py &
SERVER_PID=$!

sleep 0.8
open "http://localhost:5742"

wait $SERVER_PID
