# /review — Revisión General de Código Magento

## PROPÓSITO

Revisión completa de código Magento contra las reglas del stack de referencia.

---

## CUÁNDO EJECUTAR

- Antes de cada PR
- Al revisar código de otros
- Cuando hay dudas sobre calidad del código

---

## CRITERIOS DE REVISIÓN

| Criterio | Severidad | Qué buscar |
|----------|-----------|------------|
| ObjectManager directo | 🔴 | `ObjectManager::getInstance()` |
| Plugin en constructor | 🔴 | Plugins que interceptan `__construct` |
| SQL sin sanitizar | 🔴 | Queries raw sin bindings |
| Sin ACL en admin | 🔴 | Controllers admin sin `_isAllowed()` |
| Sin escapado en template | 🔴 | Output sin `escapeHtml()` etc. |
| Colección sin límite | 🟡 | `load()` sin `setPageSize()` |
| Sin cache tags | 🟡 | Bloques sin `getIdentities()` |
| Preference evitable | 🟡 | Rewrite donde plugin bastaría |
| Naming incorrecto | 🟢 | Vendor/módulo sin prefijo Iagt |
| Estructura no estándar | 🟢 | Carpetas fuera de convención |
| Código duplicado | 💡 | Lógica repetida extraíble |
| Optimización posible | 💡 | Queries mejorables |

---

## RESTRICCIONES

- NO corregir automáticamente — solo reportar
- NO aprobar código con 🔴
- SIEMPRE verificar ObjectManager como primera comprobación
- REFERENCIAR regla específica en cada hallazgo

---

## FORMATO DE RESPUESTA

```
## Resumen
[Veredicto: ✅ Aprobado | ⚠️ Con observaciones | ❌ Requiere corrección]

## Hallazgos críticos (🔴)
[Lista o "Ninguno"]

## Hallazgos importantes (🟡)
[Lista o "Ninguno"]

## Observaciones menores (🟢)
[Lista o "Ninguno"]

## Sugerencias (💡)
[Lista o "Ninguno"]

## Acciones requeridas
[Lista priorizada]
```

---

## EJEMPLO DE USO

```
Usuario: /review [pega código o indica archivo]

Respuesta:
## Resumen
❌ Requiere corrección — 2 hallazgos críticos

## Hallazgos críticos (🔴)
1. **Línea 45:** ObjectManager::getInstance() directo
   → Usar inyección por constructor
   
2. **Línea 78:** Output sin escapar en template
   → Usar $block->escapeHtml($value)

## Acciones requeridas
1. Refactorizar línea 45 para usar DI
2. Escapar output en línea 78
```
