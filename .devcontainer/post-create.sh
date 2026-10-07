#!/usr/bin/env bash
# Eseguito una sola volta, alla creazione del Codespace.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y --no-install-recommends postgresql-client

npm ci
sudo ln -sf "$PWD/node_modules/.bin/supabase" /usr/local/bin/supabase

supabase --version
psql --version
docker --version
