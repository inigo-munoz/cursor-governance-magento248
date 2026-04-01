#!/bin/bash
# update-governance.sh
# Actualización de governance para proyectos Magento 2
# Skeleton - adaptar cuando repos estén configurados

set -e

CORE_REPO="git@github.com:inigo-munoz/cursor-governance-core.git"
MAGENTO_REPO="git@github.com:inigo-munoz/cursor-governance-magento248.git"

GOVERNANCE_DIR="governance"
CORE_DIR="$GOVERNANCE_DIR/core"
MAGENTO_DIR="$GOVERNANCE_DIR/magento"
VERSION_FILE="GOVERNANCE.version"

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; }
log_success() { echo "[OK] $1"; }

# Validar estado
if [ ! -d "$GOVERNANCE_DIR" ]; then
    log_error "Governance no instalada. Ejecuta setup-governance.sh"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    log_error "Working directory no limpio"
    exit 1
fi

# Leer versión actual
if [ -f "$VERSION_FILE" ]; then
    CURRENT_CORE=$(grep "^CORE_VERSION=" "$VERSION_FILE" | cut -d'=' -f2)
    CURRENT_MAGENTO=$(grep "^MAGENTO_VERSION=" "$VERSION_FILE" | cut -d'=' -f2)
    echo "Versión actual: Core=$CURRENT_CORE, Magento=$CURRENT_MAGENTO"
fi

# Solicitar nuevas versiones
read -p "Nueva versión Core [$CURRENT_CORE]: " NEW_CORE
NEW_CORE=${NEW_CORE:-$CURRENT_CORE}

read -p "Nueva versión Magento [$CURRENT_MAGENTO]: " NEW_MAGENTO
NEW_MAGENTO=${NEW_MAGENTO:-$CURRENT_MAGENTO}

# Pull subtrees
log_info "Actualizando subtrees..."
git subtree pull --prefix="$CORE_DIR" "$CORE_REPO" "$NEW_CORE" --squash -m "chore: update core to $NEW_CORE"
git subtree pull --prefix="$MAGENTO_DIR" "$MAGENTO_REPO" "$NEW_MAGENTO" --squash -m "chore: update magento to $NEW_MAGENTO"

# Actualizar version file
log_info "Actualizando version file..."
# [Implementar similar a PrestaShop]

log_success "Actualización completada"
