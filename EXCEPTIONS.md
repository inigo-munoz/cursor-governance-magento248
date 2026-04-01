# EXCEPTIONS — Proceso de Excepciones

Este documento define cómo solicitar excepciones a las reglas del stack.

---

## Principio fundamental

> Las reglas existen por una razón.
> Las excepciones deben ser **excepcionales**, no la norma.

---

## ¿Qué requiere excepción formal?

| Tipo de violación | Requiere excepción formal |
|-------------------|---------------------------|
| Regla 🔴 OBLIGATORIA | ✅ Sí, siempre |
| Regla 🟡 RECOMENDADA | Solo si es recurrente |
| Patrón 🟢 OPCIONAL | No requiere |

---

## Proceso

1. Evaluar si realmente no hay alternativa
2. Documentar en `docs/exceptions/EXCEPTION-{fecha}-{descripcion}.md`
3. Obtener aprobación de Tech Lead
4. Marcar en el código con comentario referenciando la excepción

---

## Excepciones NO permitidas

Estas reglas **NO admiten excepción**:

| Regla | Por qué |
|-------|---------| 
| ObjectManager directo | Rompe DI completamente |
| SQL sin sanitizar | Riesgo crítico |
| Sin ACL en admin | Bypass de seguridad |
| Sin escapado en templates | XSS directo |

---

Última revisión: 2026-02-24
