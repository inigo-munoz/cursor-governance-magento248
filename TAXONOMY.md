# TAXONOMY — Clasificación de Reglas

Este documento define qué es **obligatorio**, qué es **recomendado** y qué es **patrón opcional** en el stack Magento.

---

## Niveles de obligatoriedad

| Nivel | Significado | Consecuencia de violar |
|-------|-------------|------------------------|
| 🔴 **OBLIGATORIO** | No negociable. Sin excepciones salvo proceso formal. | Bloquea PR. No va a producción. |
| 🟡 **RECOMENDADO** | Debe seguirse salvo justificación técnica documentada. | Genera deuda técnica si se ignora. |
| 🟢 **PATRÓN** | Buena práctica. Seguir cuando aplique. | No bloquea, pero mejora calidad. |

---

## Seguridad — 🔴 OBLIGATORIO

| Regla | Nivel |
|-------|-------|
| Escapar output en templates | 🔴 |
| Validar inputs con validators | 🔴 |
| CSRF tokens en formularios | 🔴 |
| ACL en controllers admin | 🔴 |
| No SQL raw sin bindings | 🔴 |
| Autenticación en APIs custom | 🔴 |

---

## Arquitectura — 🔴 OBLIGATORIO

| Regla | Nivel |
|-------|-------|
| Inyección por constructor | 🔴 |
| No ObjectManager directo | 🔴 |
| No plugins en constructores | 🔴 |
| Vendor `Acme` en módulos custom | 🔴 |
| Prefijo `vendor_` en tablas custom | 🔴 |

---

## Performance — 🔴/🟡 MIXTO

| Regla | Nivel |
|-------|-------|
| Colecciones con `setPageSize()` | 🔴 |
| Cache tags en bloques cacheables | 🔴 |
| Evitar N+1 en queries | 🟡 |
| Índices en columnas custom | 🟡 |
| Lazy loading donde sea posible | 🟢 |

---

## Patrones — 🟡 RECOMENDADO

| Patrón | Nivel |
|--------|-------|
| Service Contracts para lógica | 🟡 |
| Repository pattern para datos | 🟡 |
| Observers sobre plugins cuando sea posible | 🟡 |
| Data Patches para datos de setup | 🟡 |
| Declarative Schema | 🟡 |

---

## Convenciones — 🟡 RECOMENDADO

| Convención | Nivel |
|------------|-------|
| Estructura de carpetas estándar | 🟡 |
| PSR-4 autoloading | 🔴 |
| Naming conventions Magento | 🟡 |
| Comentarios en español | 🟢 |

---

## Cómo usar esta taxonomía

### En revisiones de código

```
🔴 Violación obligatoria → Bloquea PR
🟡 Violación recomendada → Comentario, no bloquea
🟢 Violación de patrón → Sugerencia
```

---

Última revisión: 2026-02-24
