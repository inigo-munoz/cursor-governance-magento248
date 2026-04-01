# Magento 2.4.8 — Architecture Guide

> Fuentes: adobe.com/commerce/php · magento/magento2 (GitHub) · Technical Guidelines oficiales
> Validado para Magento Open Source 2.4.8 · PHP 8.3

---

## Estructura de módulo

```
app/code/Iagt/<ModuleName>/
  registration.php              ← OBLIGATORIO — registra el módulo
  composer.json                 ← Metadatos y dependencias Composer
  etc/
    module.xml                  ← Declaración: nombre, versión, dependencias
    di.xml                      ← DI: plugins, preferences, virtualTypes, arguments
    events.xml                  ← Observers globales (usar con cuidado)
    frontend/
      events.xml                ← Observers solo área frontend
    adminhtml/
      events.xml                ← Observers solo área admin
    db_schema.xml               ← Declarative schema — ESTÁNDAR 2.4.8
    db_schema_whitelist.json    ← Generado con bin/magento setup:db-declaration:generate-whitelist
    webapi.xml                  ← Endpoints REST/SOAP
    acl.xml                     ← ACL resources para admin y API
    system.xml                  ← Config en admin (Stores > Configuration)
    config.xml                  ← Valores por defecto de la config
    crontab.xml                 ← Jobs de cron
  Api/
    <Entity>RepositoryInterface.php   ← Service contract — interfaz pública (@api)
    <Entity>ManagementInterface.php   ← Service contract para operaciones
    Data/
      <Entity>Interface.php           ← DTO interface (@api)
      <Entity>SearchResultsInterface.php
  Model/
    <Entity>.php                      ← Business model — implements Data\<Entity>Interface
    <Entity>Repository.php            ← implements Api\<Entity>RepositoryInterface
    ResourceModel/
      <Entity>.php                    ← DB access — extends AbstractModel
      <Entity>/
        Collection.php                ← extends AbstractCollection
  Block/
    <BlockName>.php                   ← Preferir ViewModel — Block solo para compatibilidad
  ViewModel/
    <ViewModelName>.php               ← implements ArgumentInterface — lógica de vista
  Controller/
    Adminhtml/
      <Entity>/
        Index.php
        Edit.php
        Save.php
        Delete.php
    <Entity>/
      Index.php                       ← Frontend controllers
  Observer/
    <EventName>Observer.php           ← implements ObserverInterface
  Plugin/
    <TargetClass>Plugin.php           ← Interceptors declarados en di.xml
  Setup/
    Patch/
      Data/
        <PatchName>.php               ← implements DataPatchInterface
      Schema/
        <PatchName>.php               ← implements SchemaPathaInterface (si no usa db_schema)
  view/
    frontend/
      layout/
        <handle>.xml
      templates/
        <template>.phtml
      web/
        js/
        css/
    adminhtml/
      layout/
      templates/
      ui_component/
        <entity>_listing.xml
        <entity>_form.xml
```

---

## registration.php — obligatorio en cada módulo

```php
<?php
declare(strict_types=1);

use Magento\Framework\Component\ComponentRegistrar;

ComponentRegistrar::register(
    ComponentRegistrar::MODULE,
    'Vendor_ModuleName',
    __DIR__
);
```

---

## module.xml — declaración del módulo

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Module/etc/module.xsd">
    <module name="Vendor_ModuleName" setup_version="1.0.0">
        <sequence>
            <module name="Magento_Catalog"/>  <!-- dependencias explícitas -->
            <module name="Magento_Sales"/>
        </sequence>
    </module>
</config>
```

---

## di.xml — Dependency Injection

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">

    <!-- Preference (rewrite) — ÚLTIMO RECURSO -->
    <preference for="Iagt\ModuleName\Api\EntityRepositoryInterface"
                type="Iagt\ModuleName\Model\EntityRepository"/>

    <!-- Plugin — primera opción de extensión -->
    <type name="Magento\Catalog\Model\Product">
        <plugin name="vendor_module_product_plugin"
                type="Iagt\ModuleName\Plugin\ProductPlugin"
                sortOrder="10"    <!-- gaps de 10 para inserción futura -->
                disabled="false"/>
    </type>

    <!-- VirtualType — reutilizar clase con diferente configuración -->
    <virtualType name="Iagt\ModuleName\Model\SpecialLogger"
                 type="Magento\Framework\Logger\Monolog">
        <arguments>
            <argument name="name" xsi:type="string">vendor_module</argument>
        </arguments>
    </virtualType>

    <!-- Arguments — inyectar configuración -->
    <type name="Iagt\ModuleName\Model\SomeService">
        <arguments>
            <argument name="logger" xsi:type="object">Iagt\ModuleName\Model\SpecialLogger</argument>
            <argument name="maxRetries" xsi:type="number">3</argument>
        </arguments>
    </type>
</config>
```

**Reglas de plugins:**
- `sortOrder` con gaps de 10 — permite inserción entre plugins
- `before` y `after` **únicos tipos permitidos en este proyecto**
- `around` — ❌ **PROHIBIDO** — el equipo ha decidido no usarlos
- Un plugin = una responsabilidad

---

## Service Contracts — Api/ layer

```php
<?php
declare(strict_types=1);

namespace Iagt\ModuleName\Api;

/**
 * @api
 * Interface pública del módulo — otros módulos solo pueden referenciar @api
 */
interface EntityRepositoryInterface
{
    /**
     * @param int $id
     * @return \Iagt\ModuleName\Api\Data\EntityInterface
     * @throws \Magento\Framework\Exception\NoSuchEntityException
     */
    public function getById(int $id): Data\EntityInterface;

    /**
     * @param \Magento\Framework\Api\SearchCriteriaInterface $searchCriteria
     * @return \Iagt\ModuleName\Api\Data\EntitySearchResultsInterface
     */
    public function getList(\Magento\Framework\Api\SearchCriteriaInterface $searchCriteria): Data\EntitySearchResultsInterface;

    /**
     * @param \Iagt\ModuleName\Api\Data\EntityInterface $entity
     * @return \Iagt\ModuleName\Api\Data\EntityInterface
     * @throws \Magento\Framework\Exception\CouldNotSaveException
     */
    public function save(Data\EntityInterface $entity): Data\EntityInterface;

    /**
     * @param int $id
     * @return bool
     * @throws \Magento\Framework\Exception\CouldNotDeleteException
     */
    public function deleteById(int $id): bool;
}
```

**Reglas de service contracts:**
- Solo el código `@api` puede ser referenciado por otros módulos
- Las interfaces DTO extienden `ExtensibleDataInterface` para extensibilidad
- Las jerarquías de interfaces `@api` están prohibidas
- Los setters en DTOs son la única excepción a la regla "no setters"

---

## Observers — eventos

```php
<?php
declare(strict_types=1);

namespace Iagt\ModuleName\Observer;

use Magento\Framework\Event\ObserverInterface;
use Magento\Framework\Event\Observer;

class OrderPlaceAfterObserver implements ObserverInterface
{
    public function __construct(
        private readonly OrderProcessorInterface $orderProcessor,
        private readonly LoggerInterface $logger,
    ) {}

    /**
     * Los observers NO deben modificar los objetos del evento.
     * Para modificar inputs/outputs, usar Plugins.
     */
    public function execute(Observer $observer): void
    {
        try {
            $order = $observer->getEvent()->getOrder();
            // Delegar lógica compleja al service — no inline aquí
            $this->orderProcessor->processOrder($order);
        } catch (\Exception $e) {
            // Loguear error pero NO interrumpir el flujo principal
            $this->logger->error('Order processing failed', [
                'order_id' => $order->getId(),
                'error' => $e->getMessage(),
            ]);
        }
    }
}
```

```xml
<!-- ✅ etc/frontend/events.xml — scope específico, no global -->
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd">
    <event name="sales_order_place_after">
        <observer name="vendor_module_order_place_after"
                  instance="Iagt\ModuleName\Observer\OrderPlaceAfterObserver"/>
    </event>
</config>
```

**Reglas de observers:**
- Los valores del evento **NO deben modificarse** — usar plugins para eso
- Observers tan específicos como sea posible (frontend, adminhtml, no global)
- Sin lógica de negocio compleja — delegar a services
- No crear dependencias de orden entre observers
- Capturar excepciones — un observer fallido no debe romper el flujo principal

---

## Plugins (Interceptors)

```php
<?php
declare(strict_types=1);

namespace Iagt\ModuleName\Plugin;

use Magento\Catalog\Api\ProductRepositoryInterface;
use Magento\Catalog\Api\Data\ProductInterface;

class ProductRepositoryPlugin
{
    public function __construct(
        private readonly PriceValidatorInterface $priceValidator,
    ) {}

    /**
     * Plugin before — modifica argumentos antes del método
     * @return array [modificado $product]
     */
    public function beforeSave(
        ProductRepositoryInterface $subject,
        ProductInterface $product,
        bool $saveOptions = false
    ): array {
        $this->priceValidator->validate($product);
        return [$product, $saveOptions];
    }

    /**
     * Plugin after — modifica resultado
     */
    public function afterGetById(
        ProductRepositoryInterface $subject,
        ProductInterface $result
    ): ProductInterface {
        // enriquecer resultado
        return $result;
    }

    /**
     * Plugin around — solo cuando before/after no es suficiente
     * ❌ Evitar — añade overhead considerable
     */
    // public function aroundSave(...) — justificar en comentario si se usa
}
```

---

## db_schema.xml — Declarative Schema (estándar 2.4.8)

```xml
<?xml version="1.0"?>
<schema xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Setup/Declaration/Schema/etc/schema.xsd">

    <table name="vendor_order_export" resource="default" engine="innodb"
           comment="Vendor Order Export Log">

        <column xsi:type="int" name="export_id" unsigned="true" nullable="false"
                identity="true" comment="Export ID"/>
        <column xsi:type="int" name="order_id" unsigned="true" nullable="false"
                comment="Order ID"/>
        <column xsi:type="varchar" name="status" nullable="false" length="32"
                default="pending" comment="Export Status"/>
        <column xsi:type="text" name="error_message" nullable="true"
                comment="Error Message"/>
        <column xsi:type="timestamp" name="created_at" on_update="false"
                nullable="false" default="CURRENT_TIMESTAMP" comment="Created At"/>
        <column xsi:type="timestamp" name="updated_at" on_update="true"
                nullable="false" default="CURRENT_TIMESTAMP" comment="Updated At"/>

        <constraint xsi:type="primary" referenceId="PRIMARY">
            <column name="export_id"/>
        </constraint>

        <constraint xsi:type="foreign" referenceId="VENDOR_ORDER_EXPORT_ORDER_ID_SALES_ORDER_ENTITY_ID"
                    table="vendor_order_export" column="order_id"
                    referenceTable="sales_order" referenceColumn="entity_id"
                    onDelete="CASCADE"/>

        <index referenceId="VENDOR_ORDER_EXPORT_STATUS" indexType="btree">
            <column name="status"/>
        </index>
    </table>
</schema>
```

```bash
# ⚠️  El equipo actualmente no genera db_schema_whitelist.json — es deuda técnica.
# Los módulos nuevos DEBERÍAN generarla para garantizar compatibilidad en upgrades.
# Comando para generarla:
bin/magento setup:db-declaration:generate-whitelist --module-name=Vendor_ModuleName

# Aplicar cambios de schema
bin/magento setup:upgrade
```

> **Decisión del equipo:** Las foreign keys NO se declaran en db_schema.xml.
> Las relaciones entre tablas se gestionan a nivel de aplicación (Repository pattern),
> no a nivel de base de datos. Esto evita problemas con operaciones en cascada
> no controladas.

---

## ViewModel — preferido sobre Block

```php
<?php
declare(strict_types=1);

namespace Iagt\ModuleName\ViewModel;

use Magento\Framework\View\Element\Block\ArgumentInterface;

/**
 * ViewModel — lógica de vista separada del Block
 * Testeable de forma independiente, sin herencia de Block
 */
class ProductData implements ArgumentInterface
{
    public function __construct(
        private readonly ProductRepositoryInterface $productRepository,
        private readonly StoreManagerInterface $storeManager,
    ) {}

    public function getProductById(int $id): ?ProductInterface
    {
        try {
            return $this->productRepository->getById($id);
        } catch (NoSuchEntityException $e) {
            return null;
        }
    }

    public function getCurrentStoreId(): int
    {
        return (int) $this->storeManager->getStore()->getId();
    }
}
```

```xml
<!-- Layout XML — pasar ViewModel al template -->
<block class="Magento\Framework\View\Element\Template"
       name="vendor.module.product"
       template="Vendor_ModuleName::product.phtml">
    <arguments>
        <argument name="view_model"
                  xsi:type="object">Iagt\ModuleName\ViewModel\ProductData</argument>
    </arguments>
</block>
```

```php
<!-- product.phtml -->
<?php
declare(strict_types=1);
/** @var \Iagt\ModuleName\ViewModel\ProductData $viewModel */
$viewModel = $block->getData('view_model');
?>
<p><?= $block->escapeHtml($viewModel->getProductById(1)->getName()) ?></p>
```

---

## Data Patches — migraciones de datos

```php
<?php
declare(strict_types=1);

namespace Iagt\ModuleName\Setup\Patch\Data;

use Magento\Framework\Setup\Patch\DataPatchInterface;
use Magento\Framework\Setup\Patch\PatchRevertableInterface;

class AddDefaultConfiguration implements DataPatchInterface, PatchRevertableInterface
{
    public function __construct(
        private readonly ModuleDataSetupInterface $moduleDataSetup,
        private readonly ConfigFactory $configFactory,
    ) {}

    public function apply(): self
    {
        $this->moduleDataSetup->getConnection()->startSetup();

        // Aplicar cambios de datos
        $config = $this->configFactory->create();
        $config->saveConfig('vendor_module/general/enabled', 1, 'default', 0);

        $this->moduleDataSetup->getConnection()->endSetup();
        return $this;
    }

    public function revert(): void
    {
        // Opcional — implementar si el patch es reversible
    }

    public static function getDependencies(): array
    {
        return []; // Dependencias de otros patches
    }

    public function getAliases(): array
    {
        return [];
    }
}
```

---

## Indexadores — modo Schedule (default en 2.4.8)

En Magento 2.4.8 todos los indexadores están en **Update by Schedule** por defecto.

```bash
# Verificar estado de indexadores
bin/magento indexer:status

# Ver modo actual
bin/magento indexer:show-mode

# Si es necesario cambiar modo (justificar)
bin/magento indexer:set-mode schedule catalog_product_price
bin/magento indexer:set-mode realtime catalog_category_product  # solo si es crítico
```

**Para módulos custom con indexadores:**

```xml
<!-- etc/indexer.xml -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Indexer/etc/indexer.xsd">
    <indexer id="vendor_module_entity"
             view_id="vendor_module_entity"
             class="Iagt\ModuleName\Model\Indexer\EntityIndexer"
             primary="catalog_product">
        <title translate="true">Vendor Module Entity Indexer</title>
        <description translate="true">Reindexes entities</description>
    </indexer>
</config>
```

---

## Comandos bin/magento — ciclo de desarrollo

```bash
# Después de añadir/modificar módulos
bin/magento setup:upgrade                      # actualiza schema y datos
bin/magento setup:di:compile                   # compila DI (producción)

# Static content
bin/magento setup:static-content:deploy        # producción
bin/magento setup:static-content:deploy --no-javascript --no-css  # solo lo necesario

# Cache
bin/magento cache:flush                        # limpiar todo
bin/magento cache:clean full_page              # limpiar FPC
bin/magento cache:clean config                 # después de cambios en XML

# Testing
vendor/bin/phpunit -c dev/tests/unit/phpunit.xml.dist app/code/Iagt/
vendor/bin/phpcs --standard=Magento2 app/code/Iagt/

# Análisis de módulo
bin/magento module:status
bin/magento module:enable Vendor_ModuleName
```

---

Versión: 1.0.0
Refs: developer.adobe.com/commerce/php · github.com/magento/magento2 · Technical Guidelines Adobe Commerce
