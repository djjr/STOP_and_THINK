#!/bin/bash
# ── CONFIGURATION ────────────────────────────────────────────────────────────
LOCAL_FILE="$(dirname "$0")/stdata.js"
SFTP_USER="danryane"
SFTP_HOST="innoeduvation.org"
REMOTE_PATH="/home/danryane/public_html/danryan/production/teaching/stop_and_think/stdata.js"
SSH_KEY="$HOME/.ssh/id_ed25519"
# ─────────────────────────────────────────────────────────────────────────────

echo "=============================="
echo "  Stop+Think Deploy"
echo "=============================="
echo "  Local : $LOCAL_FILE"
echo "  Remote: $SFTP_USER@$SFTP_HOST:$REMOTE_PATH"
echo ""

# Write sftp batch commands to a temp file so paths with spaces are handled cleanly
BATCH=$(mktemp)
printf 'put "%s" "%s"\nbye\n' "$LOCAL_FILE" "$REMOTE_PATH" > "$BATCH"

sftp -i "$SSH_KEY" \
     -o "User=$SFTP_USER" \
     -o "StrictHostKeyChecking=accept-new" \
     -b "$BATCH" \
     "$SFTP_HOST"

STATUS=$?
rm -f "$BATCH"

echo ""
if [ $STATUS -eq 0 ]; then
  echo "✓ Upload successful"
  osascript -e 'display notification "stdata.js uploaded successfully" with title "Stop+Think Deploy" sound name "Glass"'
else
  echo "✗ Upload failed (exit code $STATUS)"
  echo ""
  echo "Things to check:"
  echo "  1. Is your SSH key authorised on the server?"
  echo "     ssh-copy-id -i ~/.ssh/id_ed25519 $SFTP_USER@$SFTP_HOST"
  echo "  2. Does the remote directory exist?"
  echo "     $(dirname $REMOTE_PATH)"
  osascript -e 'display alert "Deploy failed" message "See the terminal window for details and suggestions." as critical'
fi

echo ""
echo "Press any key to close..."
read -n 1
