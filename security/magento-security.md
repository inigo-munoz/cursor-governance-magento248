# Magento 2.4.8 — Security Rules

> 🔴 Todo input es hostil hasta que se demuestre lo contrario.
> Caché: **Valkey 8** (fork de Redis, API compatible) — no Redis.
> CVEs activos 2026: XSS almacenado (CVSS 8.1-8.7), Path Traversal, SSRF, Incorrect Auth.
> Prioridad: Seguridad > Compatibilidad > Rendimiento.

---

## Rule 1: XSS — Escapado obligatorio en PHTML
`CWE-79` · `CVE-2026-21361, CVE-2026-21284, CVE-2026-21290` · `CVSS 8.1-8.7`

Todo output en plantillas `.phtml` DEBE escaparse con el método correcto según el contexto.

```php
// ✅ HTML context
echo $block->escapeHtml($block->getTitle());

// ✅ URL context
echo $block->escapeUrl($block->getUrl('path'));

// ✅ HTML attribute context
echo $block->escapeHtmlAttr($block->getName());

// ✅ JavaScript context
echo $block->escapeJs($block->getValue());

// ✅ CSS context
echo $block->escapeCss($value);

// ❌ PROHIBIDO — cualquiera de estos en .phtml
echo $variable;
echo $this->getData('value');
echo $block->getSomeValue();      // sin escapar
?>
<p><?= $value ?></p>              // sin escapar
<input value="<?= $attr ?>">      // sin escapar
```

**Casos especiales:**
- `/* @noEscape */` — solo si el valor ya viene escapado upstream. Documentar por qué.
- `$block->escapeHtml($html, ['b', 'i', 'strong'])` — HTML con tags permitidos

---

## Rule 2: SQL Injection
`CWE-89` · `OWASP A03:2021`

Nunca concatenar variables en queries SQL.

```php
// ✅ Correcto — Collection con addFieldToFilter
$collection = $this->collectionFactory->create();
$collection->addFieldToFilter('entity_id', ['eq' => $entityId]);

// ✅ Correcto — Repository con SearchCriteria
$searchCriteria = $this->searchCriteriaBuilder
    ->addFilter('status', 1)
    ->create();
$results = $this->repository->getList($searchCriteria);

// ✅ Correcto — query parametrizada si es inevitable
$connection = $this->resourceConnection->getConnection();
$connection->fetchAll(
    $connection->select()
        ->from('table')
        ->where('id = ?', $id)  // parametrizado
);

// ✅ quoteInto para casos excepcionales
$where = $connection->quoteInto('id = ?', $id);

// ❌ PROHIBIDO — concatenación directa
$query = "SELECT * FROM table WHERE id = " . $id;   // SQL injection
$query = "SELECT * FROM table WHERE name = '$name'"; // SQL injection
```

---

## Rule 3: CSRF — Protección en formularios POST
`CWE-352` · `OWASP A01:2021`

```php
// ✅ En templates — incluir form_key en todos los formularios POST
<form method="post" action="<?= $block->escapeUrl($block->getFormAction()) ?>">
    <?= $block->getBlockHtml('formkey') ?>
    <!-- o -->
    <input type="hidden" name="form_key"
           value="<?= $block->escapeHtmlAttr($block->getFormKey()) ?>"/>
</form>

// ✅ Controllers admin — usar _isAllowed() + form key validation
class Save extends \Magento\Backend\App\Action
{
    protected function _isAllowed(): bool
    {
        return $this->_authorization->isAllowed('Vendor_Module::save');
    }
}

// ❌ PROHIBIDO — formularios POST sin form_key
// ❌ PROHIBIDO — actions que modifican datos sin validar CSRF
```

---

## Rule 4: ACL — Control de acceso en admin
`CWE-863` · `CVE-2026-21289, CVE-2026-21309` · `CVSS 7.5`

```xml
<!-- etc/acl.xml — declarar todos los recursos -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Acl/etc/acl.xsd">
    <acl>
        <resources>
            <resource id="Magento_Backend::admin">
                <resource id="Vendor_Module::module" title="Vendor Module" sortOrder="10">
                    <resource id="Vendor_Module::view" title="View" sortOrder="10"/>
                    <resource id="Vendor_Module::save" title="Save" sortOrder="20"/>
                    <resource id="Vendor_Module::delete" title="Delete" sortOrder="30"/>
                </resource>
            </resource>
        </resources>
    </acl>
</config>
```

```php
// ✅ Verificar ACL en cada controller admin
class Index extends \Magento\Backend\App\Action
{
    const ADMIN_RESOURCE = 'Vendor_Module::view';

    protected function _isAllowed(): bool
    {
        return $this->_authorization->isAllowed(static::ADMIN_RESOURCE);
    }
}

// ✅ Verificar en API endpoints (webapi.xml)
// <resource ref="Vendor_Module::view"/>

// ❌ PROHIBIDO — controllers admin sin _isAllowed()
// ❌ PROHIBIDO — endpoints API sin resource ACL
```

---

## Rule 5: Gestión de secretos y configuración sensible
`CWE-312` · `OWASP A02:2021`

```xml
<!-- etc/system.xml — campos sensibles con Encrypted backend_model -->
<field id="api_key" type="obscure" sortOrder="10" showInDefault="1">
    <label>API Key</label>
    <backend_model>Magento\Config\Model\Config\Backend\Encrypted</backend_model>
</field>
```

```php
// ✅ Leer via ScopeConfigInterface
$apiKey = $this->scopeConfig->getValue(
    'vendor_module/general/api_key',
    \Magento\Store\Model\ScopeInterface::SCOPE_STORE
);

// ✅ Desencriptar cuando sea necesario
$decrypted = $this->encryptor->decrypt($apiKey);

// ❌ PROHIBIDO
define('API_KEY', 'sk-abc123...');                      // hardcodeada
$key = 'my-secret-password';                            // hardcodeada
$config = $this->resourceConnection->getConnection()    // acceso directo a DB
    ->fetchOne("SELECT value FROM core_config_data WHERE path = 'api_key'");
```

---

## Rule 6: Sesiones admin y configuración de seguridad
`Duo Security Web SDK v4 en 2.4.8`

```php
// ℹ️  2FA: no está activo actualmente en el proyecto.
// Si se activa en el futuro, usar Duo Web SDK v4 (el de 2.4.8).

// ✅ Session timeout configurado en admin
// Stores > Configuration > Advanced > Admin > Security > Admin Session Lifetime

// ✅ Contraseñas de admin con política de seguridad robusta
// Stores > Configuration > Advanced > Admin > Security > Password Settings
```

---

## Rule 7: Validación de input en Controllers y APIs

```php
// ✅ Validar y sanitizar todos los inputs antes de usarlos
class Save extends \Magento\Backend\App\Action
{
    public function execute()
    {
        $name = $this->getRequest()->getParam('name');

        // Validar tipo y longitud
        if (!is_string($name) || strlen($name) > 255) {
            $this->messageManager->addErrorMessage(__('Invalid name'));
            return $this->resultRedirectFactory->create()->setPath('*/*/');
        }

        // Sanitizar — nunca confiar en el input
        $name = htmlspecialchars(strip_tags($name), ENT_QUOTES, 'UTF-8');
    }
}

// ✅ Usar DataObject + validación en service
// ❌ PROHIBIDO — usar $request->getParam() directamente sin validar
// ❌ PROHIBIDO — eval(), exec() con input de usuario
```

---

## Rule 8: Path Traversal
`CWE-22` · `CVE-2026-21360` · `CVSS 6.8`

```php
// ✅ Validar rutas de archivo — nunca usar input del usuario directamente
$filename = $this->getRequest()->getParam('file');

// Normalizar y verificar que está dentro del directorio permitido
$allowedDir = realpath($this->filesystem->getDirectoryRead(DirectoryList::MEDIA)->getAbsolutePath());
$requestedPath = realpath($allowedDir . '/' . basename($filename));

if (strpos($requestedPath, $allowedDir) !== 0) {
    throw new \Magento\Framework\Exception\LocalizedException(__('Invalid file path'));
}

// ❌ PROHIBIDO
$file = $this->getRequest()->getParam('file');
file_get_contents('/var/www/html/pub/media/' . $file);  // path traversal
```

---

## Rule 9: SSRF — Server-Side Request Forgery
`CWE-918` · `CVE-2026-21293, CVE-2026-21294` · `CVSS 5.5`

```php
// ✅ Validar URLs antes de hacer requests externos
$url = $this->getRequest()->getParam('url');

// Validar que es una URL pública y no apunta a recursos internos
$parsedUrl = parse_url($url);
$blockedHosts = ['localhost', '127.0.0.1', '::1', '169.254.169.254'];

if (in_array($parsedUrl['host'] ?? '', $blockedHosts)) {
    throw new \Magento\Framework\Exception\LocalizedException(__('URL not allowed'));
}

// ❌ PROHIBIDO — hacer requests HTTP a URLs controladas por el usuario sin validar
$this->curlClient->get($this->getRequest()->getParam('webhook_url'));
```

---

## Rule 10: Dependency Injection — no ObjectManager en producción
`CWE-1076`

```php
// ❌ PROHIBIDO en producción (permitido SOLO en Factory/Test internals)
$objectManager = \Magento\Framework\App\ObjectManager::getInstance();
$product = $objectManager->create(\Magento\Catalog\Model\Product::class);

// ✅ Correcto — DI en constructor
public function __construct(
    private readonly ProductRepositoryInterface $productRepository
) {}
```

---

## Rule 11: No modificar vendor/

```
// ❌ PROHIBIDO — modificar cualquier archivo en vendor/
vendor/magento/module-catalog/Model/Product.php  ← NUNCA editar

// ✅ Correcto — Plugin, Observer o Preference en app/code/
app/code/Acme/Catalog/Plugin/ProductPlugin.php
app/code/Acme/Catalog/Observer/ProductSaveAfter.php
```

---

## Rule 12: Parches de seguridad — aplicación mensual (desde 2026)

Adobe publica parches de seguridad mensualmente desde enero 2026.
El proceso de aplicación de parches ES parte del ciclo de desarrollo.

```bash
# Verificar parches disponibles
composer outdoors | grep magento

# Aplicar parche de seguridad
composer require magento/magento2-base:2.4.8-p{N}

# Después de cada parche
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento setup:static-content:deploy
bin/magento cache:flush
```

**CVEs activos 2026 (parche p4 — marzo 2026):**
- `CVE-2026-21361, CVE-2026-21284, CVE-2026-21290` — Stored XSS · CVSS 8.1-8.7
- `CVE-2026-21289, CVE-2026-21309` — Incorrect Authorization · CVSS 7.5
- `CVE-2026-21293, CVE-2026-21294` — SSRF · CVSS 5.5
- `CVE-2026-21360` — Path Traversal · CVSS 6.8

---

## Rule 13: Logging seguro — sin PII ni datos sensibles

```php
// ✅ Correcto — loguear sin datos sensibles
$this->logger->info('Order created', ['order_id' => $orderId]);
$this->logger->error('Payment failed', ['error_code' => $code]);

// ❌ PROHIBIDO — datos sensibles en logs
$this->logger->debug('Card data', ['card_number' => $cardNumber]);  // PCI DSS violation
$this->logger->info('User data', ['password' => $password]);        // GDPR violation
$this->logger->info('API call', ['api_key' => $apiKey]);            // secrets en logs
```

---

Versión: 1.0.0
Refs: Adobe Security Bulletins APSB26-05 · OWASP Top 10 · Magento Security Best Practices
