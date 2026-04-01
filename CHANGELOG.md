# CHANGELOG — cursor-governance-magento24

Historial de cambios del stack de governance Magento 2.4.8.
Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/)

---

## [1.1.0] — 2026-03-25

### Actualizado — Adaptación al stack real del equipo (documento de recopilación)

- **`context/magento-context.md`** — reescrito con info real del equipo:
  - Stack: Valkey 8 (no Redis), Fastly CDN, MariaDB 11.4, RabbitMQ 4.1
  - Módulos terceros: Amasty_Shipping, Emarsys, MageWorks_Shipping, Channable,
    MercadoPago, MercadoPago_AdbPayment, Yotpo, Sequra_Core
  - Integración ERP SAP de pedidos
  - Tema custom hijo de Luma (RequireJS + KO.js — no Hyvä)
  - Decisiones técnicas del equipo: around plugins PROHIBIDOS, preference permitido
    con política, validación en controller (no en service), sin FK en db_schema.xml,
    sin db_schema_whitelist.json actualmente, sin 2FA, sin GraphQL, sin testing activo
  - Flujo de deploy: rama → PR staging → deploy → PR pro → deploy

- **`rules/magento-main-rule.md`** — actualizado con decisiones reales:
  - Valkey 8 y Fastly en identidad del stack
  - Plugin around: **PROHIBIDO** (política del equipo)
  - Preference: permitido con justificación escrita obligatoria
  - Sección de validación de input en Controller (no en service)

- **`security/magento-security.md`** — ajustado:
  - 2FA: no obligatorio (no activo en el proyecto actualmente)
  - Nota de Valkey 8 como servidor de caché

- **`architecture/magento-architecture.md`** — ajustado:
  - db_schema_whitelist.json: deuda técnica conocida — marcado como DEBERÍA generarse
  - Foreign keys: no se declaran en XML — documentado como decisión del equipo
  - Plugin around: PROHIBIDO — documentado en reglas de plugins

---

## [1.0.0] — 2026-03-25

### Añadido — Versión inicial

- **`manifest/stack-manifest.yml`** — Stack Magento 2.4.8 con sección `cli:` completa:
  `stack.id: magento24`, globs `**/*.php,**/*.phtml`, runtime PHP 8.3/8.4,
  plataforma OpenSearch 2.x, MariaDB 11.4, RabbitMQ 4.x

- **`rules/magento-main-rule.md`** — Rule principal con:
  estructura de módulo obligatoria, orden de extensión Plugin>Observer>Preference,
  DI correcto, db_schema.xml estándar, indexadores Update by Schedule,
  escapado obligatorio en phtml, gestión de secretos

- **`security/magento-security.md`** — 13 reglas de seguridad con CVEs activos 2026:
  XSS (CVE-2026-21361/21284/21290 CVSS 8.1-8.7), SQL injection, CSRF, ACL
  (CVE-2026-21289/21309 CVSS 7.5), secrets, 2FA Duo v4, validación de input,
  Path Traversal (CVE-2026-21360 CVSS 6.8), SSRF (CVE-2026-21293/21294 CVSS 5.5),
  ObjectManager, vendor/, logging seguro, parches mensuales

- **`architecture/magento-architecture.md`** — Guía completa:
  estructura de módulo, registration.php, module.xml, di.xml (plugins, preferences,
  virtualTypes), service contracts (@api), observers con reglas, plugins con sortOrder,
  db_schema.xml con foreign keys, ViewModel vs Block, data patches, indexadores,
  comandos bin/magento del ciclo de desarrollo

- **`conventions/magento-conventions.md`** — Convenciones de código:
  naming (módulos, clases, métodos, DB, XML), PHP 8.3 moderno (readonly, enums,
  match, named args), constructor DI, composición sobre herencia, excepciones por capa,
  logging PSR-3, layouts XML, DocBlocks, PHP_CodeSniffer Magento2, composer.json

- **`context/magento-context.md`** — Contexto del stack:
  tabla de cambios críticos de 2.4.8, requisitos de plataforma, tipos de proyectos
  Herramientas de desarrollo, modos Magento, diferencias con PrestaShop 8,
  decisiones de arquitectura documentadas, proceso de parches de seguridad

- **`patterns/magento-module-patterns.md`** — 7 patrones completos:
  Repository pattern completo (DTO + interface + implementation),
  Plugin con sortOrder correcto, Observer con delegación a Service,
  REST API endpoint custom (webapi.xml), Admin grid con UI Components,
  Cron job, Config admin con system.xml y campos encriptados

- **`agents/security-auditor.md`** — Subagent readonly de auditoría de seguridad
- **`agents/architecture-reviewer.md`** — Subagent readonly de revisión de arquitectura

---

## Historial anterior (pre-v1.0.0)

## [0.1.1] — 2026-02-24

### Corregido

- **Scripts** — `VERSION_FILE` corregido a `GOVERNANCE.version` (consistencia con contrato)
- **Alineación con Core v2.1.1**

---

## [0.1.0] — 2026-02-24

### Añadido

- Estructura inicial del stack según contrato Core
- `README.md` — Documentación principal
- `QUICKSTART.md` — Onboarding en 5 minutos
- `TAXONOMY.md` — Clasificación de reglas
- `rules/magento-main-rule.md` — Rule principal
- `commands/review.md` — Command de revisión general
- `scripts/` — Scripts de integración (skeleton)
- Carpetas obligatorias según contrato estructural

### Estado

Skeleton inicial. Pendiente desarrollo completo de:
- Políticas de seguridad detalladas
- Patrones específicos de Magento
- Commands especializados
- Documentación de arquitectura

---

## Roadmap

- [ ] v0.2.0 — Seguridad completa
- [ ] v0.3.0 — Patrones y arquitectura
- [ ] v0.4.0 — Commands especializados
- [ ] v1.0.0 — Stack completo y validado
