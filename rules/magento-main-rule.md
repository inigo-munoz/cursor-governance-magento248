# Magento Governance — Main Rule

> Stack: Magento Open Source 2.4.8 · PHP 8.3/8.4 · OpenSearch 2.x · MariaDB 11.4
> Caché: **Valkey 8** (no Redis) · CDN: **Fastly**
> Soporte hasta: abril 2028
> Prioridad: Seguridad > Compatibilidad > Rendimiento > Conveniencia

## Identidad del stack

- Plataforma: **Magento Open Source 2.4.8** (lanzado abril 2025)
- PHP: **8.3 recomendado**, 8.4 soportado — PHP 8.1 eliminado
- Search: **OpenSearch 2.x** — ElasticSearch eliminado en 2.4.8
- DB: **MariaDB 11.4 LTS**
- Caché: **Valkey 8** (fork open-source de Redis, API compatible)
- Queue: **RabbitMQ 4.1** (quorum queues — classic queues deprecated)
- CDN: **Fastly**
- Tema: tema custom hijo de **Luma** (RequireJS + KnockoutJS — no Hyvä)
- Módulos custom: `app/code/Acme/<ModuleName>/`
- Coding standard: **Magento2** (PHP_CodeSniffer)

## Arquitectura de módulos — estructura obligatoria

```
app/code/Acme/<ModuleName>/
  Api/                          ← Service contracts (interfaces públicas)
    <Entity>RepositoryInterface.php
    Data/
      <Entity>Interface.php     ← DTOs
  Block/                        ← View layer (preferir ViewModel)
  Controller/
    Adminhtml/                  ← Controllers admin
    <Action>.php                ← Controllers frontend
  Cron/                         ← Jobs programados (crontab.xml)
  Helper/                       ← Mínimo — preferir Services
  Model/
    ResourceModel/
      <Entity>.php              ← DB access
      <Entity>/
        Collection.php
    <Entity>.php                ← Business model
  Observer/                     ← Event observers (events.xml)
  Plugin/                       ← Interceptors (di.xml)
  Setup/
    Patch/
      Data/                     ← Data patches
      Schema/                   ← Schema patches (si no se usa db_schema.xml)
  ViewModel/                    ← Preferido sobre Block para lógica de vista
  etc/
    module.xml                  ← Declaración del módulo
    di.xml                      ← Dependency injection
    events.xml                  ← Observers globales
    frontend/events.xml         ← Observers solo frontend
    adminhtml/events.xml        ← Observers solo admin
    db_schema.xml               ← Declarative schema (estándar en 2.4.8)
    db_schema_whitelist.json    ← Generado automáticamente
    crontab.xml                 ← Jobs de cron
    webapi.xml                  ← REST API endpoints
    acl.xml                     ← ACL resources
    system.xml                  ← Admin config
    config.xml                  ← Config defaults
  view/
    frontend/
      layout/                   ← XML layouts
      templates/                ← .phtml templates
    adminhtml/
      layout/
      templates/
  registration.php              ← Registro del módulo (obligatorio)
  composer.json                 ← Metadatos del módulo
```

## Reglas de extensión — orden de preferencia

```
Plugin (before/after)  →  Observer  →  Preference (rewrite, último recurso)
```

1. **Plugin before/after** — primera opción siempre. Modifica inputs/outputs sin cambiar la clase
2. **Plugin around** — ❌ **PROHIBIDO en este proyecto**. Añade overhead y dificulta debugging. No usar.
3. **Observer** — para reaccionar a eventos. Sin lógica de negocio compleja en el observer
4. **Preference (rewrite)** — permitido solo si Plugin/Observer no es suficiente.
   **Requiere comentario justificando por qué no se puede usar Plugin u Observer.**

```php
// ✅ Plugin before — modificar argumentos
public function beforeSave(ProductRepositoryInterface $subject, ProductInterface $product): array
{
    // modificar $product antes del save
    return [$product];
}

// ✅ Plugin after — modificar resultado
public function afterGetPrice(Product $subject, float $result): float
{
    // modificar precio devuelto
    return $result * 1.1;
}

// ❌ Preference sin justificación — rompe upgrades
// <preference for="Magento\Catalog\Model\Product" type="Acme\Module\Model\Product"/>
```

## Dependency Injection

```php
// ✅ Constructor injection — interfaces, nunca implementaciones concretas
public function __construct(
    private readonly ProductRepositoryInterface $productRepository,
    private readonly LoggerInterface $logger,
) {}

// ✅ Factories para objetos no inyectables
public function __construct(
    private readonly ProductInterfaceFactory $productFactory,
) {}

// ❌ ObjectManager directo — prohibido en producción
$objectManager = \Magento\Framework\App\ObjectManager::getInstance();

// ❌ Inyectar implementación concreta
public function __construct(ProductRepository $productRepository) // ← no la interfaz
```

## declare(strict_types=1) — obligatorio en PHP 8.3

```php
<?php
declare(strict_types=1);

namespace Acme\ModuleName\Model;

// Todos los archivos PHP nuevos DEBEN empezar con declare(strict_types=1)
// Los archivos existentes DEBERÍAN actualizarse progresivamente
```

## Base de datos — declarative schema

```xml
<!-- etc/db_schema.xml — estándar en Magento 2.4.8 -->
<schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd">
    <table name="vendor_custom_entity" resource="default" engine="innodb"
           comment="Vendor Custom Entity">
        <column xsi:type="int" name="entity_id" unsigned="true" nullable="false"
                identity="true" comment="Entity ID"/>
        <column xsi:type="varchar" name="name" nullable="false" length="255" comment="Name"/>
        <column xsi:type="timestamp" name="created_at" on_update="false"
                nullable="false" default="CURRENT_TIMESTAMP" comment="Created At"/>
        <constraint xsi:type="primary" referenceId="PRIMARY">
            <column name="entity_id"/>
        </constraint>
    </table>
</schema>
```

- ❌ Prohibido: SQL directo en Model o Controller
- ❌ Prohibido: concatenar variables en queries → SQL injection
- ✅ Usar Repository pattern + SearchCriteria para queries
- ✅ Usar `addFieldToFilter()` en Collections con valores parametrizados

## Indexadores — Update by Schedule (default en 2.4.8)

En 2.4.8 todos los indexadores son **Update by Schedule** por defecto.
El código custom NO debe forzar reindexado inmediato en operaciones de save.

```php
// ❌ Evitar — forzar reindexado inmediato
$this->indexer->reindexRow($productId);

// ✅ Correcto — los indexadores se ejecutan via cron automáticamente
// Solo forzar si es absolutamente necesario y justificado
```

## Seguridad en plantillas PHTML

```php
// ✅ SIEMPRE escapar antes de hacer output
echo $block->escapeHtml($variable);
echo $block->escapeUrl($url);
echo $block->escapeHtmlAttr($attribute);
echo $block->escapeJs($jsValue);

// ❌ PROHIBIDO — output directo sin escapar
echo $variable;           // XSS
echo $this->getData('x'); // XSS — CVEs 2026 CVSS 8.1-8.7
```

## Validación de input — en el Controller

El equipo valida los parámetros de entrada en el **Controller**, no en el Service.

```php
// ✅ Validar en el controller antes de pasar al service
class Save extends \Magento\Backend\App\Action
{
    public function execute()
    {
        $name = $this->getRequest()->getParam('name');

        // Validar en el controller
        if (!is_string($name) || strlen($name) > 255 || empty(trim($name))) {
            $this->messageManager->addErrorMessage(__('Nombre inválido'));
            return $this->resultRedirectFactory->create()->setPath('*/*/');
        }

        // Pasar al service ya validado
        $this->entityService->save(['name' => trim($name)]);
    }
}

// ❌ No validar en el service (decisión del equipo)
// El service recibe datos ya validados del controller
```

## Configuración y secretos

```php
// ✅ Leer config via ScopeConfigInterface
$value = $this->scopeConfig->getValue(
    'vendor_module/general/api_key',
    ScopeInterface::SCOPE_STORE
);

// ✅ Valores sensibles — encriptados en system.xml con backend_model
// <backend_model>Magento\Config\Model\Config\Backend\Encrypted</backend_model>

// ❌ Prohibido: hardcodear API keys, passwords, secrets en código
// ❌ Prohibido: leer core_config_data directamente (sin ScopeConfigInterface)
```

## CLI commands

```php
// Declarar en etc/di.xml — obligatorio para funcionalidad de admin/dev
// Siempre en área global — si necesita área específica, setearla explícitamente
// Las excepciones NO deben romper el CLI framework
```

## @references

@architecture/magento-architecture.md
@security/magento-security.md
@conventions/magento-conventions.md
@context/magento-context.md
@patterns/magento-module-patterns.md
