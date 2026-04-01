# Contexto — Magento 2.4.8 Stack

## Stack tecnológico real del proyecto

| Tecnología | Versión | Notas |
|-----------|---------|-------|
| Magento Open Source | 2.4.8 | Soporte hasta abril 2028 |
| PHP | 8.3 | 8.4 soportado, 8.1 prohibido |
| Base de datos | MariaDB 11.4 | MariaDB 11.4 LTS |
| Motor de búsqueda | OpenSearch 2.x | ElasticSearch eliminado |
| Caché | **Valkey 8** | Sustituto de Redis compatible — no Redis |
| Message queue | RabbitMQ 4.1 | Quorum queues, classic deprecated |
| Servidor web | Nginx | — |
| CDN | **Fastly** | CDN en producción |
| Entorno local | Docker | — |

> **Nota importante:** El stack usa **Valkey 8** como servidor de caché,
> no Redis. Valkey es el fork open-source de Redis compatible con la API
> de Redis. Las configuraciones de caché y sesión deben usar Valkey.

## Módulos de terceros instalados

| Módulo | Para qué sirve |
|--------|----------------|
| Amasty_Shipping | Gestión avanzada de envíos |
| Emarsys | Marketing automation / email |
| MageWorks_Shipping | Métodos de envío adicionales |
| Magento2_Channable | Integración con marketplace Channable |
| MercadoPago | Pasarela de pago (Latinoamérica) |
| MercadoPago_AdbPayment | Pago avanzado MercadoPago |
| Yotpo_Yotpo | Reviews y UGC |
| Sequra_Core | Financiación / pago aplazado |

El agente debe conocer estos módulos para evitar conflictos de nombres,
plugins duplicados y referencias a sus interfaces internas.

## Integraciones externas

**ERP SAP** — integración automática de pedidos. El agente debe asumir
que cualquier evento relacionado con pedidos puede tener observadores
o plugins de la integración SAP activos.

## Tema frontend

**Tema custom hijo de Luma** — la tienda usa un tema custom basado en Luma.

- Stack JS: **RequireJS + KnockoutJS + UI Components** (no Hyvä)
- Sin jQuery UI widgets activos (fileUploader reemplazado por Uppy en 2.4.8)
- Los layouts se extienden desde Luma — nunca sobreescribir core

## Decisiones técnicas del equipo

**Plugin around — prohibido** salvo justificación documentada.
El equipo ha decidido no usar `around` plugins — añaden overhead
y dificultan el debugging. Solo `before` y `after`.

**Preference (rewrite) — permitido con política**. No está prohibido
pero requiere justificación escrita en el código comentando por qué
no es posible usar Plugin u Observer.

**Validación de input — en el Controller, no en el Service**.
El equipo valida los parámetros de entrada en el controller antes de
pasarlos al service. Diferente al patrón genérico de Adobe Commerce
que sugiere validar en el service.

**db_schema_whitelist.json — no se genera** actualmente. Es una deuda
técnica conocida. Los módulos nuevos deberían generarla.

**Foreign keys en XML — no se declaran** en db_schema.xml. El equipo
gestiona las relaciones a nivel de aplicación, no de base de datos.

**2FA — no activo** en el proyecto actualmente. No es un requisito
obligatorio del equipo.

**GraphQL — no se usa**. La tienda no tiene frontend desacoplado.
No es necesario desarrollar resolvers GraphQL.

**Testing — sin cobertura definida**. El equipo no tiene métricas
de cobertura ni herramientas activas de testing configuradas.
Es una deuda técnica pendiente.

## Módulo de referencia

`Code/Flex` — módulo custom existente que sirve de referencia para
las convenciones de código del equipo.

## Flujo de deploy

```
Rama de feature
    ↓ Pull Request
Staging → Deploy staging
    ↓ Pull Request
Pro → Deploy pro
```

Pipeline en Bitbucket con los comandos estándar:
- `bin/magento setup:upgrade`
- `bin/magento setup:di:compile`
- `bin/magento setup:static-content:deploy`

Deploy con zero-downtime (modo mantenimiento gestionado).
Parches de seguridad mensuales planificados desde enero 2026.

## Cambios críticos de 2.4.8

| Cambio | Impacto en el desarrollo |
|--------|--------------------------|
| PHP 8.1 eliminado | declare(strict_types=1) en archivos nuevos. Sin null en non-nullable. |
| ElasticSearch → OpenSearch 2.x | OpenSearch 2.x obligatorio. Revisar integraciones búsqueda custom. |
| Indexadores → Update by Schedule | No forzar reindexado inmediato en save. |
| TinyMCE 5 → 7.3.0 | API incompatible con v5. Revisar customizaciones WYSIWYG. |
| league/flysystem 2.x → 3.x | Actualizar módulos que usen flysystem directamente. |
| CVEs activos 2026 | XSS (CVSS 8.1-8.7), Path Traversal, SSRF. Parches mensuales. |

## Diferencias con PrestaShop 8 (otro stack de referencia)

| Aspecto | PrestaShop 8 | Magento 2.4.8 |
|---------|-------------|----------------|
| Lenguaje | PHP 8.3/8.4 | PHP 8.3/8.4 |
| Extensión | Hooks, override | Plugin > Observer > Preference |
| DB | MySQL | MariaDB 11.4 (Valkey para caché) |
| Frontend | Smarty (.tpl) | PHTML + RequireJS + KO.js |
| Testing | Sin definir | Sin definir (deuda técnica) |
| CDN | No especificado | Fastly |
