# Magento 2.4.8 — Module Patterns

> Patrones probados para módulos custom en Magento 2.4.8
> Fuente: magento/magento2 (GitHub) · developer.adobe.com

---

## Patrón 1: Repository Pattern completo

El patrón estándar de Magento para acceso a datos. Obligatorio en módulos con entidades propias.

```php
// Api/Data/ExportInterface.php — DTO
<?php
declare(strict_types=1);
namespace Acme\OrderExport\Api\Data;

/** @api */
interface ExportInterface extends \Magento\Framework\Api\ExtensibleDataInterface
{
    const EXPORT_ID    = 'export_id';
    const ORDER_ID     = 'order_id';
    const STATUS       = 'status';
    const CREATED_AT   = 'created_at';

    public function getExportId(): ?int;
    public function setExportId(int $id): self;
    public function getOrderId(): int;
    public function setOrderId(int $orderId): self;
    public function getStatus(): string;
    public function setStatus(string $status): self;
}

// Api/ExportRepositoryInterface.php — service contract
<?php
declare(strict_types=1);
namespace Acme\OrderExport\Api;

/** @api */
interface ExportRepositoryInterface
{
    public function getById(int $id): Data\ExportInterface;
    public function getList(\Magento\Framework\Api\SearchCriteriaInterface $criteria): Data\ExportSearchResultsInterface;
    public function save(Data\ExportInterface $export): Data\ExportInterface;
    public function delete(Data\ExportInterface $export): bool;
    public function deleteById(int $id): bool;
}

// Model/Export.php — implementación del DTO
<?php
declare(strict_types=1);
namespace Acme\OrderExport\Model;

use Acme\OrderExport\Api\Data\ExportInterface;
use Magento\Framework\Model\AbstractModel;

class Export extends AbstractModel implements ExportInterface
{
    protected function _construct(): void
    {
        $this->_init(ResourceModel\Export::class);
    }

    public function getExportId(): ?int
    {
        return $this->getData(self::EXPORT_ID) ? (int)$this->getData(self::EXPORT_ID) : null;
    }

    public function setExportId(int $id): self
    {
        return $this->setData(self::EXPORT_ID, $id);
    }
    // ... resto de getters/setters
}

// Model/ExportRepository.php — implementación del repository
<?php
declare(strict_types=1);
namespace Acme\OrderExport\Model;

use Acme\OrderExport\Api\ExportRepositoryInterface;
use Acme\OrderExport\Api\Data\ExportInterface;
use Magento\Framework\Exception\NoSuchEntityException;
use Magento\Framework\Exception\CouldNotSaveException;
use Magento\Framework\Exception\CouldNotDeleteException;

class ExportRepository implements ExportRepositoryInterface
{
    public function __construct(
        private readonly ResourceModel\Export $resource,
        private readonly ExportFactory $exportFactory,
        private readonly ResourceModel\Export\CollectionFactory $collectionFactory,
        private readonly Data\ExportSearchResultsInterfaceFactory $searchResultsFactory,
        private readonly \Magento\Framework\Api\SearchCriteria\CollectionProcessorInterface $collectionProcessor,
    ) {}

    public function getById(int $id): ExportInterface
    {
        $export = $this->exportFactory->create();
        $this->resource->load($export, $id);

        if (!$export->getId()) {
            throw new NoSuchEntityException(
                __('Export with id "%1" does not exist.', $id)
            );
        }
        return $export;
    }

    public function getList(\Magento\Framework\Api\SearchCriteriaInterface $criteria): Data\ExportSearchResultsInterface
    {
        $collection = $this->collectionFactory->create();
        $this->collectionProcessor->process($criteria, $collection);

        $searchResults = $this->searchResultsFactory->create();
        $searchResults->setSearchCriteria($criteria);
        $searchResults->setItems($collection->getItems());
        $searchResults->setTotalCount($collection->getSize());

        return $searchResults;
    }

    public function save(ExportInterface $export): ExportInterface
    {
        try {
            $this->resource->save($export);
        } catch (\Exception $e) {
            throw new CouldNotSaveException(
                __('Could not save export: %1', $e->getMessage()),
                $e
            );
        }
        return $export;
    }

    public function deleteById(int $id): bool
    {
        return $this->delete($this->getById($id));
    }

    public function delete(ExportInterface $export): bool
    {
        try {
            $this->resource->delete($export);
        } catch (\Exception $e) {
            throw new CouldNotDeleteException(
                __('Could not delete export: %1', $e->getMessage()),
                $e
            );
        }
        return true;
    }
}
```

---

## Patrón 2: Plugin con sortOrder correcto

```php
// Plugin/ProductPricePlugin.php
<?php
declare(strict_types=1);
namespace Acme\Pricing\Plugin;

use Magento\Catalog\Api\Data\ProductInterface;
use Magento\Catalog\Api\ProductRepositoryInterface;

class ProductPricePlugin
{
    public function __construct(
        private readonly PriceAdjusterInterface $priceAdjuster,
        private readonly StoreManagerInterface $storeManager,
    ) {}

    /**
     * Aplicar precio especial antes del save.
     * sortOrder=10 en di.xml — permite a otros plugins ejecutar antes (sortOrder<10)
     * o después (sortOrder>10) de este.
     *
     * @return array [$product, $saveOptions]
     */
    public function beforeSave(
        ProductRepositoryInterface $subject,
        ProductInterface $product,
        bool $saveOptions = false
    ): array {
        $adjustedPrice = $this->priceAdjuster->adjust(
            $product->getPrice(),
            $this->storeManager->getStore()->getId()
        );
        $product->setPrice($adjustedPrice);

        return [$product, $saveOptions];
    }

    /**
     * Loguear después del save sin modificar el resultado.
     */
    public function afterSave(
        ProductRepositoryInterface $subject,
        ProductInterface $result
    ): ProductInterface {
        // enriquecer/loguear, no modificar datos críticos
        return $result;
    }
}
```

```xml
<!-- etc/di.xml -->
<type name="Magento\Catalog\Api\ProductRepositoryInterface">
    <plugin name="vendor_pricing_product_price"
            type="Acme\Pricing\Plugin\ProductPricePlugin"
            sortOrder="10"/>
            <!-- gaps de 10 para permitir inserción entre plugins -->
</type>
```

---

## Patrón 3: Observer con delegación a Service

```php
// Observer/OrderExportAfterObserver.php
<?php
declare(strict_types=1);
namespace Acme\OrderExport\Observer;

use Magento\Framework\Event\ObserverInterface;
use Magento\Framework\Event\Observer;

class OrderExportAfterObserver implements ObserverInterface
{
    public function __construct(
        private readonly OrderExporterInterface $orderExporter,
        private readonly \Psr\Log\LoggerInterface $logger,
    ) {}

    /**
     * REGLA: No modificar objetos del evento — usar plugins para eso.
     * REGLA: Sin lógica compleja — delegar al service.
     * REGLA: Capturar excepciones — no romper el flujo principal.
     */
    public function execute(Observer $observer): void
    {
        try {
            /** @var \Magento\Sales\Model\Order $order */
            $order = $observer->getEvent()->getOrder();

            // Delegar lógica al service
            $this->orderExporter->queueForExport($order->getId());

        } catch (\Exception $e) {
            // Loguear sin interrumpir el flujo de Magento
            $this->logger->error('Failed to queue order for export', [
                'order_id' => $order->getId() ?? 'unknown',
                'error'    => $e->getMessage(),
            ]);
        }
    }
}
```

```xml
<!-- etc/adminhtml/events.xml — scope específico, no global -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Event/etc/events.xsd">
    <event name="sales_order_save_after">
        <observer name="vendor_order_export_after"
                  instance="Acme\OrderExport\Observer\OrderExportAfterObserver"/>
    </event>
</config>
```

---

## Patrón 4: REST API endpoint custom

```xml
<!-- etc/webapi.xml -->
<?xml version="1.0"?>
<routes xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Webapi:etc/webapi.xsd">

    <route url="/V1/vendor/exports" method="GET">
        <service class="Acme\OrderExport\Api\ExportRepositoryInterface" method="getList"/>
        <resources>
            <resource ref="Acme_OrderExport::view"/>
        </resources>
    </route>

    <route url="/V1/vendor/exports/:id" method="GET">
        <service class="Acme\OrderExport\Api\ExportRepositoryInterface" method="getById"/>
        <resources>
            <resource ref="Acme_OrderExport::view"/>
        </resources>
    </route>

    <route url="/V1/vendor/exports" method="POST">
        <service class="Acme\OrderExport\Api\ExportRepositoryInterface" method="save"/>
        <resources>
            <resource ref="Acme_OrderExport::save"/>
        </resources>
    </route>

    <!-- Endpoint público (sin autenticación) -->
    <route url="/V1/vendor/exports/status/:token" method="GET">
        <service class="Acme\OrderExport\Api\ExportStatusInterface" method="getByToken"/>
        <resources>
            <resource ref="anonymous"/>
        </resources>
    </route>
</routes>
```

---

## Patrón 5: Admin grid con UI Components

```xml
<!-- view/adminhtml/ui_component/vendor_export_listing.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<listing xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Ui:etc/ui_configuration.xsd">

    <argument name="data" xsi:type="array">
        <item name="js_config" xsi:type="array">
            <item name="provider" xsi:type="string">vendor_export_listing.vendor_export_listing_data_source</item>
        </item>
    </argument>

    <settings>
        <buttons>
            <button name="add">
                <url path="*/*/new"/>
                <class>primary</class>
                <label translate="true">Add New Export</label>
            </button>
        </buttons>
        <spinner>vendor_export_columns</spinner>
        <deps>
            <dep>vendor_export_listing.vendor_export_listing_data_source</dep>
        </deps>
    </settings>

    <dataSource name="vendor_export_listing_data_source" component="Magento_Ui/js/grid/provider">
        <settings>
            <storageConfig>
                <param name="indexField" xsi:type="string">export_id</param>
            </storageConfig>
            <updateUrl path="mui/index/render"/>
        </settings>
        <aclResource>Acme_OrderExport::view</aclResource>
        <dataProvider class="Magento\Framework\View\Element\UiComponent\DataProvider\DataProvider"
                      name="vendor_export_listing_data_source">
            <settings>
                <requestFieldName>id</requestFieldName>
                <primaryFieldName>export_id</primaryFieldName>
            </settings>
        </dataProvider>
    </dataSource>

    <listingToolbar name="listing_top">
        <settings>
            <sticky>true</sticky>
        </settings>
        <paging name="listing_paging"/>
        <filters name="listing_filters"/>
        <massaction name="listing_massaction">
            <action name="delete">
                <settings>
                    <confirm>
                        <message translate="true">Delete selected exports?</message>
                        <title translate="true">Delete items</title>
                    </confirm>
                    <url path="vendor_export/export/massDelete"/>
                    <type>delete</type>
                    <label translate="true">Delete</label>
                </settings>
            </action>
        </massaction>
    </listingToolbar>

    <columns name="vendor_export_columns">
        <selectionsColumn name="ids">
            <settings>
                <indexField>export_id</indexField>
            </settings>
        </selectionsColumn>

        <column name="export_id">
            <settings>
                <filter>textRange</filter>
                <label translate="true">ID</label>
                <sorting>asc</sorting>
            </settings>
        </column>

        <column name="order_id">
            <settings>
                <filter>text</filter>
                <label translate="true">Order ID</label>
            </settings>
        </column>

        <column name="status">
            <settings>
                <filter>select</filter>
                <label translate="true">Status</label>
            </settings>
        </column>

        <column name="created_at" class="Magento\Ui\Component\Listing\Columns\Date"
                component="Magento_Ui/js/grid/columns/date">
            <settings>
                <filter>dateRange</filter>
                <dataType>date</dataType>
                <label translate="true">Created At</label>
            </settings>
        </column>

        <actionsColumn name="actions" class="Acme\OrderExport\Ui\Component\Listing\Column\ExportActions">
            <settings>
                <indexField>export_id</indexField>
            </settings>
        </actionsColumn>
    </columns>
</listing>
```

---

## Patrón 6: Cron job

```xml
<!-- etc/crontab.xml -->
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/crontab.xsd">
    <group id="default">
        <job name="vendor_order_export_process"
             instance="Acme\OrderExport\Cron\ProcessPendingExports"
             method="execute">
            <schedule>*/15 * * * *</schedule>  <!-- cada 15 minutos -->
        </job>
    </group>
</config>
```

```php
// Cron/ProcessPendingExports.php
<?php
declare(strict_types=1);
namespace Acme\OrderExport\Cron;

class ProcessPendingExports
{
    public function __construct(
        private readonly ExportProcessorInterface $processor,
        private readonly \Psr\Log\LoggerInterface $logger,
    ) {}

    public function execute(): void
    {
        try {
            $processed = $this->processor->processPending();
            $this->logger->info('Cron export completed', ['processed' => $processed]);
        } catch (\Exception $e) {
            $this->logger->error('Cron export failed', ['error' => $e->getMessage()]);
            // No relanzar — los crons no deben propagar excepciones
        }
    }
}
```

---

## Patrón 7: Config admin con system.xml

```xml
<!-- etc/system.xml -->
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Config:etc/system_file.xsd">
    <system>
        <tab id="vendor" translate="label" sortOrder="300">
            <label>Vendor</label>
        </tab>

        <section id="vendor_export" translate="label" type="text" sortOrder="10" showInDefault="1"
                 showInWebsite="1" showInStore="1">
            <tab>vendor</tab>
            <label>Order Export</label>
            <resource>Acme_OrderExport::config</resource>

            <group id="general" translate="label" type="text" sortOrder="10"
                   showInDefault="1" showInWebsite="1" showInStore="1">
                <label>General</label>

                <field id="enabled" translate="label" type="select" sortOrder="10"
                       showInDefault="1" showInWebsite="1" showInStore="1">
                    <label>Enable</label>
                    <source_model>Magento\Config\Model\Config\Source\Yesno</source_model>
                </field>

                <field id="api_endpoint" translate="label" type="text" sortOrder="20"
                       showInDefault="1" showInWebsite="0" showInStore="0">
                    <label>API Endpoint</label>
                    <validate>required-entry validate-url</validate>
                    <comment>URL del endpoint de exportación</comment>
                </field>

                <field id="api_key" translate="label" type="obscure" sortOrder="30"
                       showInDefault="1" showInWebsite="0" showInStore="0">
                    <label>API Key</label>
                    <!-- Encrypted backend — obligatorio para secretos -->
                    <backend_model>Magento\Config\Model\Config\Backend\Encrypted</backend_model>
                </field>
            </group>
        </section>
    </system>
</config>
```

---

Versión: 1.0.0
Refs: github.com/magento/magento2 · developer.adobe.com/commerce/php
