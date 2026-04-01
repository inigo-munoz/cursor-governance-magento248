# Magento 2.4.8 — Coding Conventions

> Estándar oficial: Magento2 (PHP_CodeSniffer)
> Fuente: developer.adobe.com/commerce/php/coding-standards/
> PHP 8.3 · PSR-12 · Technical Guidelines Adobe Commerce

---

## Naming — módulos y namespaces

```
Vendor namespace:   Iagt
Módulo:             Iagt\NombreModulo
Nombre completo:    Iagt_NombreModulo (Magento convention)
Directorio:         app/code/Iagt/NombreModulo/
```

```php
// Namespaces — UpperCamelCase
namespace Iagt\CustomerSync\Model;
namespace Iagt\CustomerSync\Api\Data;
namespace Iagt\CustomerSync\Controller\Adminhtml\Entity;

// ❌ Prohibido
namespace Vendor\CustomerSync\model;  // lowercase
namespace Iagt_CustomerSync;        // underscore en namespace PHP
```

---

## Naming — clases y archivos

```php
// Clases — UpperCamelCase, un archivo por clase
CustomerRepository.php         → class CustomerRepository
CustomerRepositoryInterface.php → interface CustomerRepositoryInterface
OrderPlaceAfterObserver.php    → class OrderPlaceAfterObserver
ProductPlugin.php              → class ProductPlugin
AddDefaultConfig.php           → class AddDefaultConfig (Data Patch)

// Convención por tipo de clase
<Entity>Repository.php         ← Repository
<Entity>RepositoryInterface.php ← Service contract
<Entity>Interface.php          ← DTO interface
<Entity>Factory.php            ← Factory (generada automáticamente por Magento)
<EventName>Observer.php        ← Observer
<TargetClass>Plugin.php        ← Plugin
<BlockName>Block.php           ← Block (o solo <BlockName>.php)
<ViewModelName>.php            ← ViewModel
```

---

## Naming — métodos y propiedades

```php
// Métodos — lowerCamelCase
public function getProductById(int $id): ProductInterface {}
public function saveOrder(OrderInterface $order): OrderInterface {}
public function isActive(): bool {}
private function processItems(array $items): array {}

// Propiedades — lowerCamelCase, tipadas
private ProductRepositoryInterface $productRepository;
private readonly LoggerInterface $logger;  // readonly en PHP 8.1+

// Constantes — UPPER_SNAKE_CASE
const STATUS_PENDING = 'pending';
const STATUS_EXPORTED = 'exported';
const MAX_RETRY_COUNT = 3;

// Config paths — snake_case con namespace del módulo
const CONFIG_PATH_ENABLED = 'vendor_module/general/enabled';
const CONFIG_PATH_API_KEY  = 'vendor_module/api/key';
```

---

## Naming — DB y XML

```sql
-- Tablas — snake_case con prefijo del vendor
vendor_order_export
vendor_customer_sync_log
vendor_entity_data

-- Columnas — snake_case
entity_id, order_id, created_at, updated_at, is_active
```

```xml
<!-- Eventos custom — snake_case con prefijo vendor -->
<event name="vendor_order_exported_after">
<event name="vendor_lead_created_before">

<!-- Config paths — vendor_module/section/field -->
<path>vendor_module/general/enabled</path>
<path>vendor_module/api/endpoint</path>

<!-- ACL resource IDs -->
<resource id="Vendor_Module::view_orders"/>
<resource id="Vendor_Module::export_orders"/>

<!-- DI plugin names — snake_case -->
<plugin name="vendor_module_product_price_plugin" .../>
<plugin name="vendor_module_order_save_before_plugin" .../>
```

---

## PHP 8.3 — código moderno obligatorio

```php
<?php
declare(strict_types=1);  // OBLIGATORIO en todos los archivos PHP nuevos

namespace Iagt\ModuleName\Model;

// ✅ Tipos explícitos en parámetros y retorno
public function getById(int $id): ProductInterface {}
public function isActive(): bool {}
public function getItems(): array {}
public function getName(): ?string {} // nullable con ?

// ✅ Readonly properties (PHP 8.1+)
class OrderExporter
{
    public function __construct(
        private readonly OrderRepositoryInterface $orderRepository,
        private readonly LoggerInterface $logger,
        private readonly string $exportEndpoint,
    ) {}
}

// ✅ Enums (PHP 8.1+) para estados
enum ExportStatus: string
{
    case Pending = 'pending';
    case Exported = 'exported';
    case Failed = 'failed';
}

// ✅ Match expression (PHP 8.0+)
$message = match($status) {
    'pending'  => __('Pending export'),
    'exported' => __('Successfully exported'),
    'failed'   => __('Export failed'),
    default    => __('Unknown status'),
};

// ✅ Named arguments (PHP 8.0+)
$this->productRepository->getList(searchCriteria: $searchCriteria);

// ❌ Prohibido — código legacy PHP 7
$price = (float) null;   // PHP 8.3 deprecación strict
function process($item)  // sin tipos
```

---

## Constructor y DI

```php
// ✅ Constructor — solo asignación y validación
public function __construct(
    private readonly ProductRepositoryInterface $productRepository,
    private readonly LoggerInterface $logger,
    private readonly int $maxRetries = 3,          // argumento con default
) {
    if ($maxRetries < 1) {
        throw new \InvalidArgumentException('maxRetries must be >= 1');
    }
    // Sin lógica de negocio, sin eventos, sin queries
}

// ❌ Prohibido en constructor
public function __construct(EventManager $eventManager)
{
    $eventManager->dispatch('module_init');  // ❌ eventos en constructor
    $this->data = $this->loadData();         // ❌ lógica en constructor
}

// ❌ Proxies e interceptores — nunca inyectar explícitamente
public function __construct(ProductRepository\Interceptor $repo) {} // ❌
public function __construct(ProductRepository\Proxy $repo) {}       // ❌
```

---

## Composición sobre herencia

```php
// ✅ Composición — preferida según Technical Guidelines Adobe
class OrderProcessor
{
    public function __construct(
        private readonly ValidatorInterface $validator,
        private readonly ExporterInterface $exporter,
        private readonly LoggerInterface $logger,
    ) {}

    public function process(OrderInterface $order): void
    {
        $this->validator->validate($order);
        $this->exporter->export($order);
    }
}

// ❌ Herencia — evitar excepto cuando Magento lo requiere
class OrderProcessor extends AbstractOrderProcessor  // ← evitar
{
    protected function validate($order) {}  // sobreescribir método protected
}

// ✅ Herencia permitida — extender clases de Magento cuando es obligatorio
class Save extends \Magento\Backend\App\Action {}  // Controller admin
class Collection extends \Magento\Framework\Model\ResourceModel\Db\Collection\AbstractCollection {}
```

---

## Manejo de excepciones

```php
// ✅ Jerarquía de excepciones por capa
use Magento\Framework\Exception\NoSuchEntityException;
use Magento\Framework\Exception\CouldNotSaveException;
use Magento\Framework\Exception\CouldNotDeleteException;
use Magento\Framework\Exception\LocalizedException;

// En Repository
public function getById(int $id): EntityInterface
{
    $entity = $this->entityFactory->create();
    $this->resource->load($entity, $id);

    if (!$entity->getId()) {
        throw new NoSuchEntityException(
            __('Entity with id "%1" does not exist.', $id)
        );
    }
    return $entity;
}

public function save(EntityInterface $entity): EntityInterface
{
    try {
        $this->resource->save($entity);
    } catch (\Exception $e) {
        throw new CouldNotSaveException(
            __('Could not save entity: %1', $e->getMessage()),
            $e  // preservar stack trace original
        );
    }
    return $entity;
}

// ✅ No usar \Exception genérico como tipo thrown
// ✅ Excepciones específicas según la operación
// ❌ Prohibido — excepciones para control de flujo
if ($this->productExists($sku)) {
    throw new \Exception('Product exists'); // ❌ usar conditional, no exception
}

// ✅ Envolver librerías de terceros en try/catch
try {
    $result = $this->externalLibrary->doSomething();
} catch (\ExternalException $e) {
    throw new LocalizedException(__('External service failed: %1', $e->getMessage()), $e);
}
```

---

## Logging

```php
// ✅ Logger inyectado — nunca instanciado directamente
public function __construct(
    private readonly \Psr\Log\LoggerInterface $logger
) {}

// ✅ Niveles correctos
$this->logger->debug('Processing started', ['entity_id' => $id]);   // desarrollo
$this->logger->info('Order exported', ['order_id' => $orderId]);    // operaciones
$this->logger->warning('Retry attempt', ['attempt' => $attempt]);   // advertencias
$this->logger->error('Export failed', ['error' => $e->getMessage()]); // errores

// ❌ Prohibido
error_log('something');              // función PHP nativa
$this->_logger->log('info', '...');  // underscore prefix (Magento 1 style)

// ❌ Datos sensibles en logs
$this->logger->info('Customer', ['email' => $email, 'password' => $pass]); // GDPR
```

---

## Layouts XML

```xml
<!-- ✅ Extender layouts existentes — nunca sobreescribir core -->
<!-- app/code/Iagt/Module/view/frontend/layout/catalog_product_view.xml -->
<?xml version="1.0"?>
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <!-- Solo añadir/modificar lo necesario -->
        <referenceBlock name="product.info.main">
            <block class="Magento\Framework\View\Element\Template"
                   name="vendor.module.custom.block"
                   template="Vendor_Module::custom.phtml"
                   after="product.info.price">
                <arguments>
                    <argument name="view_model"
                              xsi:type="object">Iagt\Module\ViewModel\CustomData</argument>
                </arguments>
            </block>
        </referenceBlock>
    </body>
</page>

<!-- ❌ Prohibido — modificar layouts de vendor/ directamente -->
<!-- ❌ cacheable="false" sin justificación documentada — impacta FPC -->
```

---

## DocBlocks

```php
/**
 * Exporta una orden al sistema externo.
 *
 * @param OrderInterface $order La orden a exportar
 * @return bool True si se exportó correctamente
 * @throws CouldNotSaveException Si falla el guardado del log
 * @throws LocalizedException Si el servicio externo no está disponible
 */
public function export(OrderInterface $order): bool
{
    // ...
}

// ✅ Documentar: parámetros, retorno, excepciones lanzadas
// ✅ @api en interfaces públicas
// ❌ No documentar lo que es obvio por los tipos
// ❌ No usar @var para tipos que el compilador puede inferir
```

---

## PHP_CodeSniffer — validación

```bash
# Validar módulo con Magento2 standard
vendor/bin/phpcs --standard=Magento2 app/code/Iagt/ModuleName/

# Fix automático de problemas triviales
vendor/bin/phpcbf --standard=Magento2 app/code/Iagt/ModuleName/

# Análisis estático con PHPStan
vendor/bin/phpstan analyse app/code/Iagt/ModuleName/ --level=5

# Integrar en pre-commit hook
#!/bin/bash
vendor/bin/phpcs --standard=Magento2 --extensions=php $(git diff --cached --name-only | grep '\.php$')
```

---

## Composer — gestión de dependencias

```json
// composer.json del módulo
{
    "name": "vendor/module-name",
    "description": "Vendor ModuleName for Magento 2",
    "type": "magento2-module",
    "version": "1.0.0",
    "require": {
        "php": ">=8.3",
        "magento/framework": ">=103.0",
        "magento/module-catalog": "*"
    },
    "autoload": {
        "files": ["registration.php"],
        "psr-4": {
            "Iagt\\ModuleName\\": ""
        }
    }
}
```

---

Versión: 1.0.0
Refs: developer.adobe.com/commerce/php/coding-standards/ · PSR-12 · PHP 8.3
