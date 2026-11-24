#!/bin/sh
set -eu

if [ -n "${DATABASE_HOST:-}" ]; then
  if [ -z "${DATABASE_USER:-}" ] || [ -z "${DATABASE_NAME:-}" ]; then
    echo "DATABASE_USER and DATABASE_NAME are required"
    exit 1
  fi

  export DATABASE_URL="$(node -e 'const e=process.env; const enc=encodeURIComponent; process.stdout.write("mysql://"+enc(e.DATABASE_USER)+":"+enc(e.DATABASE_PASSWORD||"")+"@"+e.DATABASE_HOST+":"+(e.DATABASE_PORT||"3306")+"/"+e.DATABASE_NAME)')"
  export NODE_PATH="/opt/prisma-cli/node_modules${NODE_PATH:+:$NODE_PATH}"

  i=0
  until node /opt/prisma-cli/node_modules/prisma/build/index.js db push; do
    i=$((i + 1))
    if [ "$i" -ge 15 ]; then
      echo "prisma db push failed"
      exit 1
    fi
    echo "Waiting for database..."
    sleep 2
  done
fi

exec node server.js
