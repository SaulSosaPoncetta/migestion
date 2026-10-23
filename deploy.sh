#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Deploy manual de la landing estática (migestion.com.ar)
#
# Uso, en el VPS:
#     cd /var/www/landing
#     bash deploy.sh
#
# Baja los cambios de origin/main y ajusta permisos de lectura para Nginx.
# =============================================================================
set -Eeuo pipefail

BRANCH="main"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"
APP_NAME="$(basename "$APP_DIR")"

paso()  { echo -e "\n\033[1;34m==> $1\033[0m"; }
ok()    { echo -e "\033[1;32m$1\033[0m"; }
aviso() { echo -e "\033[1;33m$1\033[0m"; }
error() { echo -e "\033[1;31m$1\033[0m"; }

trap 'error "\nEl deploy de $APP_NAME falló en la línea $LINENO."' ERR

echo -e "\033[1mDeploy de $APP_NAME — $(date '+%d/%m/%Y %H:%M:%S')\033[0m"

# -----------------------------------------------------------------------------
paso "Verificando el repositorio"
RAMA_ACTUAL="$(git rev-parse --abbrev-ref HEAD)"
if [ "$RAMA_ACTUAL" != "$BRANCH" ]; then
    error "El servidor está en la rama '$RAMA_ACTUAL' y el deploy es desde '$BRANCH'."
    exit 1
fi

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    error "Hay archivos modificados en el servidor que no están en git:"
    git status --short --untracked-files=no
    error "Hacé esos cambios en tu PC, o descartalos con 'git checkout -- <archivo>', y reintentá."
    exit 1
fi
ok "OK: rama $BRANCH, sin cambios locales."

# -----------------------------------------------------------------------------
paso "Bajando cambios de origin/$BRANCH"
ANTES="$(git rev-parse --short HEAD)"
git fetch origin "$BRANCH"
git merge --ff-only "origin/$BRANCH"
DESPUES="$(git rev-parse --short HEAD)"

if [ "$ANTES" = "$DESPUES" ]; then
    aviso "No hay commits nuevos (sigue en $ANTES)."
else
    ok "Actualizado $ANTES -> $DESPUES:"
    git log --oneline "$ANTES..$DESPUES"
fi

# -----------------------------------------------------------------------------
paso "Ajustando permisos de lectura"
find . -path ./.git -prune -o -type d -exec chmod 755 {} +
find . -path ./.git -prune -o -type f -exec chmod 644 {} +

ok "\nDeploy de $APP_NAME terminado (versión $DESPUES)."
