# QUICKSTART — Onboarding en 5 minutos

## ¿Qué es esto?

Este repositorio define **cómo debe escribirse código Magento 2** en tu equipo.

No es opcional. No es sugerencia. Es el estándar técnico obligatorio.

---

## Lo mínimo que debes saber

### 1. Prioridad técnica (memorízala)

```
Seguridad > Estabilidad > Performance > Arquitectura > Funcionalidad > Rapidez
```

Si tienes que elegir entre "funciona" y "es seguro", elige seguro.
Si tienes que elegir entre "rápido de hacer" y "performante", elige performante.

---

### 2. Las 6 reglas que nunca puedes romper

| Regla | Qué significa |
|-------|---------------|
| **No plugins en constructores** | Plugins en `__construct` causan loops infinitos |
| **Inyección por constructor** | Nunca `ObjectManager::getInstance()` directo |
| **Colecciones con límite** | Toda colección debe tener `setPageSize()` |
| **Cache tags correctos** | Todo bloque cacheable debe declarar tags |
| **Escapado en templates** | `$block->escapeHtml()` para todo output |
| **Prefijo en tablas custom** | Tablas propias con prefijo `vendor_` |

---

### 3. Prefijo obligatorio

Todos los módulos custom deben usar vendor `Acme`:

```
app/code/Acme/MiModulo/
```

Namespace:
```php
namespace Acme\MiModulo;
```

---

### 4. Antes de hacer PR

Ejecuta estos commands en orden:

```
1. /review              → Revisión general (siempre)
2. /security-check      → Si tocaste inputs, APIs o datos sensibles
3. /performance-check   → Si tocaste colecciones, queries o cache
```

Si `/review` indica 🔴 → **NO puede ir a producción**.

---

### 5. Dónde está todo

| Necesitas... | Ubicación |
|--------------|-----------|
| Reglas principales | `rules/magento-main-rule.md` |
| Seguridad detallada | `security/magento-security.md` |
| Patrones recomendados | `patterns/magento-patterns.md` |
| Arquitectura | `architecture/magento-architecture.md` |
| Commands disponibles | `commands/` |

---

### 6. Si tienes dudas

1. Lee `rules/magento-main-rule.md` (3 min)
2. Si no está claro → pregunta al Tech Lead
3. Si necesitas excepción → documéntala (ver `EXCEPTIONS.md`)

---

## Checklist rápido antes de PR

```
[ ] ¿Mis clases usan inyección por constructor?
[ ] ¿Mis colecciones tienen límite?
[ ] ¿Mis bloques declaran cache tags?
[ ] ¿Escapé todo output en templates?
[ ] ¿Mi módulo usa vendor Acme?
[ ] ¿Ejecuté /review?
```

Si alguna respuesta es NO → corrige antes de PR.

---

## Anti-patrones críticos en Magento

```php
// ❌ NUNCA
$objectManager = \Magento\Framework\App\ObjectManager::getInstance();
$product = $objectManager->create('Magento\Catalog\Model\Product');

// ✅ SIEMPRE
public function __construct(
    \Magento\Catalog\Model\ProductFactory $productFactory
) {
    $this->productFactory = $productFactory;
}
```

```php
// ❌ NUNCA - colección sin límite
$collection = $this->collectionFactory->create();
foreach ($collection as $item) { ... }

// ✅ SIEMPRE
$collection = $this->collectionFactory->create();
$collection->setPageSize(100);
foreach ($collection as $item) { ... }
```

---

## Tiempo estimado de lectura completa

| Documento | Tiempo | Prioridad |
|-----------|--------|-----------|
| Este quickstart | 5 min | 🔴 Obligatorio |
| `magento-main-rule.md` | 5 min | 🔴 Obligatorio |
| `magento-security.md` | 15 min | 🔴 Primera semana |
| `magento-patterns.md` | 20 min | 🟡 Primera semana |
| Resto de documentación | Variable | 🟢 Según necesidad |

---

**Bienvenido al stack Magento del equipo.**
