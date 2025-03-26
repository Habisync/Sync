#!/bin/bash

set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/sync-cosmic-theme"
BACKUP_DIR="$PROJECT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
POINTS_FILE="$PROJECT_DIR/.stellar_points"
CDN_URL="https://cdn.sync-cosmic.com"

# Functions
rollback() { [ -d "$BACKUP_DIR" ] && cp -r "$BACKUP_DIR"/* "$PROJECT_DIR"; exit 1; }
check_deps() {
  for dep in git npm jq; do
    if ! command -v "$dep" &>/dev/null; then
      case "$dep" in
        "git") sudo apt-get install -y git || rollback ;;
        "npm") curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs || rollback ;;
        "jq") sudo apt-get install -y jq || rollback ;;
      esac
    fi
  done
}
add_points() { echo $(( $(cat "$POINTS_FILE" 2>/dev/null || echo 0) + $1 )) > "$POINTS_FILE"; }

# Start
check_deps

# Setup Directory
[ -d "$PROJECT_DIR" ] && { cp -r "$PROJECT_DIR" "$BACKUP_DIR" || rollback; rm -rf "$PROJECT_DIR"/* || rollback; }
mkdir -p "$PROJECT_DIR" "{src,templates,assets,scripts,src/custom}" || rollback
cd "$PROJECT_DIR" || rollback
git init || rollback
add_points 25

# Base Configs
create_file() {
  [ -f "$1" ] && return
  echo "$2" > "$1" || rollback
}

create_file "$PROJECT_DIR/package.json" '{
  "name": "sync-cosmic-theme",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "shopify-push": "shopify theme push",
    "test": "jest --coverage",
    "lint": "eslint . --ext .ts,.tsx",
    "format": "prettier --write ."
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "three": "^0.149.0",
    "framer-motion": "^10.0.0",
    "@reduxjs/toolkit": "^1.9.0",
    "react-redux": "^8.0.0",
    "gsap": "^3.11.0",
    "@shopify/shopify-api": "^7.0.0",
    "react-router-dom": "^6.0.0",
    "dompurify": "^3.0.0",
    "lodash": "^4.17.21",
    "react-share": "^4.4.0",
    "howler": "^2.2.3"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.0.0",
    "vite": "^4.0.0",
    "eslint": "^8.0.0",
    "prettier": "^2.8.0",
    "jest": "^29.0.0",
    "@testing-library/react": "^14.0.0"
  }
}'

create_file "$PROJECT_DIR/vite.config.ts" 'import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: { outDir: "dist", assetsDir: "assets", sourcemap: true, minify: "esbuild" },
  server: { port: 3000 }
});'

create_file "$PROJECT_DIR/src/index.css" '@tailwind base;
@tailwind components;
@tailwind utilities;

:root { --cosmicVoid: #0A0A1A; --silver200: #E5E4E2; --purple500: #9B5DE5; }
[data-theme="dark"] { --cosmicVoid: #1A1A2E; --silver200: #D1D0CE; }'

create_file "$PROJECT_DIR/src/store.ts" "$(cat src/store.ts)"  # Assume content from original
create_file "$PROJECT_DIR/src/main.tsx" "$(cat src/main.tsx)"  # Assume content from original

npm ci --production || rollback
add_points 100

# Templates
jq -c '.pages[]' pages.json | while IFS= read -r line; do
  FILE=$(echo "$line" | jq -r '.file')
  TITLE=$(echo "$line" | jq -r '.title')
  NEBULA=$(echo "$line" | jq -r '.nebula')
  create_file "templates/${FILE}.liquid" "<!DOCTYPE html><html lang=\"en\"><head><title>${TITLE}</title><link rel=\"stylesheet\" href=\"${CDN_URL}/styles.css\"></head><body data-theme=\"dark\" data-nebula=\"${NEBULA}\"><div id=\"root\"></div></body></html>"
done
add_points 200

# Components
create_file "src/components/CosmicNav.tsx" "$(cat src/components/CosmicNav.tsx)"
create_file "src/components/PageWrapper.tsx" "$(cat src/components/PageWrapper.tsx)"

# Finalize
add_points 300