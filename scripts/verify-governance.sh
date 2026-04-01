#!/bin/bash
# verify-governance.sh
# Verificación de governance para CI/CD - Magento
# Skeleton - completar según necesidades

set -e

GOVERNANCE_DIR="governance"
MAGENTO_DIR="$GOVERNANCE_DIR/magento"
CURSOR_RULES_DIR=".cursor/rules"
RULE_FILE="$CURSOR_RULES_DIR/magento.md"
VERSION_FILE="GOVERNANCE.version"

EXIT_CODE=0

log_check() { echo "[CHECK] $1"; }
log_pass() { echo "[PASS]  $1"; }
log_fail() { echo "[FAIL]  $1"; EXIT_CODE=1; }

# Verificar estructura
log_check "Estructura de governance..."
[ -d "$GOVERNANCE_DIR" ] || log_fail "governance/ no existe"
[ -d "$MAGENTO_DIR" ] || log_fail "governance/magento/ no existe"

# Verificar rule
log_check "Rule de Cursor..."
[ -f "$RULE_FILE" ] || log_fail "Rule no existe: $RULE_FILE"

# Verificar unicidad
log_check "Unicidad de rule..."
RULE_COUNT=$(find "$CURSOR_RULES_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
[ "$RULE_COUNT" -eq 1 ] || log_fail "Hay $RULE_COUNT rules (debe ser 1)"

# Verificar version file
log_check "Version file..."
[ -f "$VERSION_FILE" ] || log_fail "No existe $VERSION_FILE"

# Verificar contenido de rule
log_check "Contenido de rule..."
if ! grep -q "Seguridad > Estabilidad > Performance" "$RULE_FILE" 2>/dev/null; then
    log_fail "Rule no contiene identificador esperado"
fi

# Resumen
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "✅ Verificación exitosa"
else
    echo "❌ Verificación fallida"
fi

exit $EXIT_CODE
