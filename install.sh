#!/bin/sh
set -eu

REPO_URL="${REPO_URL:-https://github.com/sujianleo/RTL-skills}"
BRANCH="${BRANCH:-main}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
DEST="$CODEX_HOME/skills"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$DEST"

echo "Downloading Codex skills from:"
echo "  $REPO_URL"
echo

curl -fsSL "$REPO_URL/archive/refs/heads/$BRANCH.tar.gz" \
  | tar -xz --strip-components=1 -C "$TMP_DIR"

if [ ! -d "$TMP_DIR/skills" ]; then
  echo "ERROR: skills/ directory not found in repo."
  exit 1
fi

cp -R "$TMP_DIR/skills/." "$DEST/"

echo
echo "Installed Codex skills to:"
echo "  $DEST"
echo
echo "Done."
