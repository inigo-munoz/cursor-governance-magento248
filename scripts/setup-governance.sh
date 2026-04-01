#!/bin/bash
# setup-governance.sh
# Setup de governance para proyectos Magento 2
# Skeleton - adaptar repos cuando estén creados

set -e

# ============================================================
# CONFIGURACIÓN - EDITAR SEGÚN VERSIÓN
# ============================================================

CORE_REPO="git@github.com:inigo-munoz/cursor-governance-core.git"
MAGENTO_REPO="git@github.com:inigo-munoz/cursor-governance-magento248.git"

CORE_REF="v2.1.1"
MAGENTO_REF="v0.1.1"

GOVERNANCE_DIR="governance"
CORE_DIR="$GOVERNANCE_DIR/core"
MAGENTO_DIR="$GOVERNANCE_DIR/magento"
CURSOR_RULES_DIR=".cursor/rules"
RULE_SOURCE="$MAGENTO_DIR/rules/magento-main-rule.md"
RULE_TARGET="$CURSOR_RULES_DIR/magento.md"
VERSION_FILE="GOVERNANCE.version"

RULE_IDENTIFIER="Seguridad > Estabilidad > Performance"

# ============================================================
# FUNCIONES
# ============================================================

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1" >&2; }
log_success() { echo "[OK] $1"; }

compute_hash() {
    local file="$1"
    if command -v sha256sum &> /dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        echo "no-hash-tool"
    fi
}

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# ============================================================
# VALIDACIONES
# ============================================================

validate_prerequisites() {
    log_info "Validando prerequisitos..."
    
    if [ ! -d ".git" ]; then
        log_error "No estás en la raíz de un repositorio git."
        exit 1
    fi
    
    if [ -d "$GOVERNANCE_DIR" ]; then
        log_error "Governance ya instalada. Usa update-governance.sh"
        exit 1
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        log_error "Working directory no limpio. Haz commit o stash."
        exit 1
    fi
    
    log_success "Prerequisitos OK"
}

# ============================================================
# SUBTREES
# ============================================================

add_subtrees() {
    log_info "Añadiendo subtrees..."
    
    git subtree add --prefix="$CORE_DIR" "$CORE_REPO" "$CORE_REF" --squash
    git subtree add --prefix="$MAGENTO_DIR" "$MAGENTO_REPO" "$MAGENTO_REF" --squash
    
    log_success "Subtrees añadidos"
}

# ============================================================
# CURSOR
# ============================================================

setup_cursor() {
    log_info "Configurando Cursor..."
    
    mkdir -p "$CURSOR_RULES_DIR"
    
    local os=$(detect_os)
    if [ "$os" = "windows" ]; then
        cp "$RULE_SOURCE" "$RULE_TARGET"
    else
        ln -sf "../../$RULE_SOURCE" "$RULE_TARGET" 2>/dev/null || cp "$RULE_SOURCE" "$RULE_TARGET"
    fi
    
    log_success "Cursor configurado"
}

# ============================================================
# VERSION FILE
# ============================================================

generate_version_file() {
    log_info "Generando version file..."
    
    local rule_hash=$(compute_hash "$RULE_SOURCE")
    local today=$(date +%Y-%m-%d)
    
    local core_sha=$(git ls-remote "$CORE_REPO" "$CORE_REF" 2>/dev/null | cut -f1)
    local magento_sha=$(git ls-remote "$MAGENTO_REPO" "$MAGENTO_REF" 2>/dev/null | cut -f1)
    
    [ -z "$core_sha" ] && core_sha="unknown"
    [ -z "$magento_sha" ] && magento_sha="unknown"
    
    cat > "$VERSION_FILE" << EOF
# GOVERNANCE VERSION - Magento Stack
CORE_VERSION=$CORE_REF
MAGENTO_VERSION=$MAGENTO_REF
CORE_COMMIT=$core_sha
MAGENTO_COMMIT=$magento_sha
RULE_HASH=$rule_hash
LAST_SYNC=$today
EOF

    log_success "Version file generado"
}

# ============================================================
# CURSORIGNORE
# ============================================================

create_cursorignore() {
    log_info "Creando .cursorignore..."
    
    cat > .cursorignore << 'EOF'
# Magento 2 cursorignore
vendor/
node_modules/
var/cache/
var/page_cache/
var/view_preprocessed/
var/generation/
var/di/
var/log/
pub/static/
generated/
.git/
governance/core/
EOF

    log_success ".cursorignore creado"
}

# ============================================================
# MAIN
# ============================================================

main() {
    echo "============================================================"
    echo "  Governance Setup - Magento"
    echo "============================================================"
    
    validate_prerequisites
    add_subtrees
    setup_cursor
    create_cursorignore
    generate_version_file
    
    echo ""
    log_success "Setup completado"
    echo ""
    echo "Próximos pasos:"
    echo "  1. git add -A"
    echo "  2. git commit -m 'chore: add governance'"
    echo "  3. Abrir Cursor y verificar Settings → Rules"
}

main "$@"
