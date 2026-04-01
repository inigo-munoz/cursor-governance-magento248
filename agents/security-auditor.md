---
name: security-auditor
description: |
  Audita seguridad en código PHP/Magento. Lee en paralelo, nunca modifica.
  Foco: XSS en phtml, SQL injection, CSRF, ACL, secrets hardcodeados, Path Traversal, SSRF.
  CVEs activos 2026: CVE-2026-21361/21284/21290 (XSS CVSS 8.1-8.7), CVE-2026-21289/21309 (Auth CVSS 7.5).
tools:
  - read_file
  - list_directory
  - search_files
readonly: true
---

# Security Auditor — Magento 2.4.8

## Checklist de auditoría

### XSS (máxima prioridad — CVEs activos 2026)
- [ ] Todo output en `.phtml` usa `$block->escapeHtml()`, `escapeUrl()`, `escapeHtmlAttr()`, `escapeJs()`
- [ ] Sin `echo $variable` directo en templates
- [ ] Los `/* @noEscape */` están justificados

### SQL Injection
- [ ] Sin concatenación de variables en queries SQL
- [ ] Collections usan `addFieldToFilter()` con valores parametrizados
- [ ] Sin SQL raw en Models o Controllers

### CSRF y ACL
- [ ] Formularios POST incluyen `form_key`
- [ ] Controllers admin implementan `_isAllowed()` con `const ADMIN_RESOURCE`
- [ ] Endpoints webapi.xml tienen `<resource ref="..."/>`

### Secrets
- [ ] Sin API keys hardcodeadas
- [ ] Config sensible usa `Encrypted` backend_model
- [ ] Sin datos sensibles en logs

### Path Traversal / SSRF / ObjectManager
- [ ] Rutas de archivo validadas con `realpath()` y verificación de directorio
- [ ] URLs externas del usuario validadas antes de requests HTTP
- [ ] Sin `ObjectManager::getInstance()` fuera de Factory/Test
