#!/usr/bin/env bash
set -euo pipefail

# Usage: PKG_URL=https://... GITHUB_TOKEN=ghp_... DESKTOP_URL=https://... ./install_deb.sh

PKG_URL="${1:-${PKG_URL:-}}"
GITHUB_TOKEN="${2:-${GITHUB_TOKEN:-}}"
DESKTOP_URL="${3:-${DESKTOP_URL:-}}"

if [[ -z "$PKG_URL" ]]; then
  echo "Erreur : PKG_URL non défini." >&2
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Erreur : GITHUB_TOKEN non défini." >&2
  exit 1
fi

if [[ -z "$DESKTOP_URL" ]]; then
  echo "Erreur : DESKTOP_URL non défini." >&2
  exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# --- Téléchargement du .deb (repo privé) ---
echo "==> Téléchargement du paquet depuis : $PKG_URL"
ZIP_FILE="$WORKDIR/package.zip"
curl -fsSL \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/octet-stream" \
  "$PKG_URL" -o "$ZIP_FILE"

echo "==> Décompression..."
unzip -q "$ZIP_FILE" -d "$WORKDIR/extracted"

DEB_FILE=$(find "$WORKDIR/extracted" -name "*.deb" | head -n 1)
if [[ -z "$DEB_FILE" ]]; then
  echo "Erreur : aucun fichier .deb trouvé dans l'archive." >&2
  exit 1
fi

echo "==> Installation de : $(basename "$DEB_FILE")"
sudo dpkg -i "$DEB_FILE"
sudo apt-get install -f -y

# --- Téléchargement du .desktop (ressource publique) ---
echo "==> Téléchargement du fichier .desktop depuis : $DESKTOP_URL"
DESKTOP_FILE="$WORKDIR/pacman-tauri.desktop"
curl -fsSL "$DESKTOP_URL" -o "$DESKTOP_FILE"

# Détection du bureau (supporte Desktop et Bureau)
DESKTOP_DIR="${XDG_DESKTOP_DIR:-}"
if [[ -z "$DESKTOP_DIR" ]]; then
  if [[ -d "$HOME/Bureau" ]]; then
    DESKTOP_DIR="$HOME/Bureau"
  else
    DESKTOP_DIR="$HOME/Desktop"
  fi
fi

echo "==> Copie du fichier .desktop sur le bureau : $DESKTOP_DIR"
cp "$DESKTOP_FILE" "$DESKTOP_DIR/pacman-tauri.desktop"
chmod 755 "$DESKTOP_DIR/pacman-tauri.desktop"

echo "==> Installation terminée avec succès."
