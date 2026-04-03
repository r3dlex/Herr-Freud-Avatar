#!/bin/bash
set -e

echo "=== Herr Freud Setup ==="

# Check Elixir
if ! command -v elixir &> /dev/null; then
    echo "Error: Elixir is required. Install from https://elixir-lang.org/install.html"
    exit 1
fi

# Check Erlang
if ! command -v erl &> /dev/null; then
    echo "Error: Erlang is required."
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
mix deps.get

# Create data directories
echo "Creating data directories..."
mkdir -p data/input
mkdir -p data/sessions
mkdir -p data/nudges

# Setup database
echo "Running database migrations..."
mix ecto.create
mix ecto.migrate

# Seed interaction styles
echo "Seeding interaction styles..."
mix run priv/repo/seeds.exs

# Copy .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env from .env.example. Please fill in your MINIMAX_API_KEY."
fi

echo ""
echo "=== Setup Complete ==="
echo "Copy .env.example to .env and add your MINIMAX_API_KEY"
echo "Then run: mix phx.server  (not applicable in Phase 1)"
echo "Or run: iex -S mix"
