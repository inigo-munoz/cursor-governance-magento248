# CONTRIBUTING — Cómo Contribuir al Stack

Este documento define cómo proponer cambios, mejoras o correcciones al stack Magento.

---

## Proceso de contribución

### Cambios menores
```
Contributor → PR → 1 Maintainer approval → Merge
```

### Cambios significativos
```
Contributor → RFC → Discusión → PR → 2 approvals → Merge
```

---

## Formato de commits

```
tipo(área): descripción corta

Tipos: fix, docs, feat, refactor, chore
```

Ejemplos:
```
fix(security): corregir ejemplo de escapado
feat(commands): añadir performance-check command
docs(patterns): documentar repository pattern
```

---

## Proceso de PR

1. Crear branch: `tipo/descripcion-corta`
2. Hacer cambios siguiendo estructura existente
3. Actualizar CHANGELOG si aplica
4. Crear PR con descripción clara
5. Esperar revisión

---

## Qué NO contribuir

- Reglas específicas de un proyecto (van en el proyecto)
- Código de módulos (esto es solo gobernanza)
- Cambios que contradicen el Core

---

Última revisión: 2026-02-24
