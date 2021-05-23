#!/bin/bash

# Get dependencies ready
mix deps.get
mix deps.compile

# Compile assets
cd apps/rumbl_web/assets​ && npm install && npm run build && cd​​ ​​../../..​ && mix phx.digest

# Set-up server
mix ecto.create
mix ecto.migrate
mix run apps/rumbl/priv/repo/seeds.exs

# Start server
mix phx.server
