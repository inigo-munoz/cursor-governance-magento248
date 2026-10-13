# PR CHECKLIST — Verificación antes de Merge

Copiar este checklist en la descripción del PR.

---

## Checklist

### 🔴 Seguridad (obligatorio)

```
[ ] Output escapado en templates (escapeHtml, escapeUrl, etc.)
[ ] Inputs validados con validators
[ ] CSRF tokens en formularios
[ ] ACL configurado en controllers admin
[ ] No SQL raw sin bindings
[ ] APIs custom tienen autenticación
```

### 🔴 Arquitectura (obligatorio)

```
[ ] Inyección de dependencias por constructor
[ ] No uso de ObjectManager::getInstance()
[ ] No plugins en constructores
[ ] Módulo usa vendor Acme
[ ] Tablas custom usan prefijo vendor_
```

### 🔴 Performance (obligatorio)

```
[ ] Colecciones tienen setPageSize()
[ ] Bloques cacheables tienen cache_tags
[ ] No hay N+1 queries obvios
```

### 🟡 Commands ejecutados

```
[ ] Ejecuté /review
[ ] Ejecuté /security-check (si aplica)
[ ] Ejecuté /performance-check (si aplica)
```

### 🟡 Calidad

```
[ ] El código funciona en local
[ ] He probado el flujo completo
[ ] Sigue convenciones de naming
```

---

## Declaración

```
[ ] Confirmo que he revisado este checklist honestamente
```

---

Última revisión: 2026-02-24
