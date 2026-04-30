

#!/usr/bin/env bash
set -euo pipefail

PKG_URL="${1:-${PKG_URL:-}}"
GITHUB_TOKEN="${2:-${GITHUB_TOKEN:-}}"

if [[ -z "$PKG_URL" ]]; then
  echo "Erreur : PKG_URL non défini." >&2
  echo "Usage : PKG_URL=https://... GITHUB_TOKEN=ghp_... $0" >&2
  exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Erreur : GITHUB_TOKEN non défini." >&2
  exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Téléchargement depuis : $PKG_URL"
ZIP_FILE="$WORKDIR/package.zip"
curl -fsSL \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/octet-stream" \
  "$PKG_URL" -o "$ZIP_FILE"

echo "==> Décompression..."
unzip -q "$ZIP_FILE" -d "$WORKDIR/extracted"

# Recherche du premier .deb extrait
DEB_FILE=$(find "$WORKDIR/extracted" -name "*.deb" | head -n 1)

if [[ -z "$DEB_FILE" ]]; then
  echo "Erreur : aucun fichier .deb trouvé dans l'archive." >&2
  exit 1
fi

echo "==> Installation de : $(basename "$DEB_FILE")"
sudo dpkg -i "$DEB_FILE"

# Résoudre les éventuelles dépendances manquantes
sudo apt-get install -f -y

echo "==> Installation terminée avec succès."