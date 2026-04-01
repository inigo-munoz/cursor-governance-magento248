# Governance — Magento Stack

Stack de gobernanza técnica para proyectos Magento 2.

---

## Propósito

Definir reglas, patrones y herramientas para desarrollo Magento 2 en tu equipo.

---

## Alcance

Este stack cubre:
- Desarrollo de módulos custom
- Extensión de funcionalidad core
- Integraciones con sistemas externos
- Personalización de frontend (Luma/Hyvä)
- APIs REST y GraphQL

---

## Prioridad técnica

```
Seguridad > Estabilidad > Performance > Arquitectura > Funcionalidad > Rapidez
```

En Magento, Performance tiene peso especial por la complejidad inherente del framework.

---

## Estructura del repositorio

```
cursor-governance-magento/
├── README.md                    ← Este archivo
├── CHANGELOG.md
├── QUICKSTART.md                ← Onboarding en 5 min
├── TAXONOMY.md                  ← Qué es obligatorio/recomendado
├── CONTRIBUTING.md              ← Cómo contribuir
├── PR_CHECKLIST.md              ← Checklist antes de merge
├── EXCEPTIONS.md                ← Proceso de excepciones
│
├── rules/                       ← Rule principal para Cursor
├── commands/                    ← Commands de revisión
├── scripts/                     ← Setup/update/verify
├── security/                    ← Políticas de seguridad
├── patterns/                    ← Patrones Magento
├── conventions/                 ← Convenciones de código
├── architecture/                ← Arquitectura Magento
├── context/                     ← Restricciones del framework
├── standards/                   ← Estándares de desarrollo
├── workflow/                    ← Flujo de trabajo
│
└── [opcionales]/
    ├── integrations/            ← ERPs, PIMs, etc.
    ├── migration/               ← M1 a M2, upgrades
    └── skills/                  ← Skills especializadas
```

---

## Jerarquía documental

1. **rules/magento-main-rule.md** — Hard guardrails (siempre activo)
2. **security/** — Políticas de seguridad
3. **patterns/** — Patrones recomendados
4. **commands/** — Herramientas de revisión
5. Resto de documentación — Contexto y referencia

---

## Uso con Cursor

```bash
# En proyecto Magento
./scripts/setup-governance.sh

# Verificar
./scripts/verify-governance.sh

# Ejecutar revisión
/review
```

---

## Versionado

Este stack sigue versionado semántico independiente del Core.

**Versión actual:** v0.1.0 (skeleton)

---

## Relación con Core

Este stack cumple el contrato estructural definido en:
`cursor-governance-core/framework/stack-structure.md`
