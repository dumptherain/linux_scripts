#!/usr/bin/env bash
# get_chat_id.sh — prints the latest chat ID seen by your bot

if [ -z "$1" ]; then
  echo "Usage: $0 <TELEGRAM_BOT_TOKEN>"
  exit 1
fi

TOKEN="$1"
API="https://api.telegram.org/bot${TOKEN}"

# Fetch updates and extract the last chat.id
chat_id=$(curl -s "${API}/getUpdates" \
  | jq -r '.result | last | .message.chat.id // empty')

if [ -z "$chat_id" ]; then
  echo "No chat ID found. Have you sent a message to your bot yet?"
  exit 1
fi

echo "$chat_id"

