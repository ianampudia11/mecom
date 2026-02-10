# 📋 Plan de Refactorización - Archivo routes.ts

## 🔍 Análisis Actual

### Archivos más grandes del proyecto:
- **routes.ts**: 18,202 líneas (752 KB) ⚠️ CRÍTICO
- **flow-executor.ts**: 2,375 líneas (116 KB) ⚠️ 
- **CampaignBuilder.tsx**: ~2,000 líneas

### Problema Principal
El archivo `server/routes.ts` es **monolítico y difícil de mantener**:
- Más de 18,000 líneas de código
- Mezcla múltiples dominios (contacts, tasks, deals, messages, etc.)
- Dificulta encontrar y corregir bugs
- Hace lento el desarrollo y code reviews

## 🎯 Estrategia de Refactorización

Veo que ya existe una estructura modular en `server/modules/` con subdirectorios como:
- `server/modules/contacts/`
- `server/modules/tasks/`
- etc.

### Propuesta: Modularizar por Dominio

Dividir `routes.ts` en **módulos de rutas independientes** organizados por dominio de negocio.

## 📦 Estructura Propuesta

```
server/
├── routes/
│   ├── index.ts                    # Router principal (100-200 líneas)
│   ├── auth.routes.ts              # Autenticación y sesiones
│   ├── contacts.routes.ts          # Rutas de contactos
│   ├── conversations.routes.ts     # Rutas de conversaciones
│   ├── messages.routes.ts          # Rutas de mensajes
│   ├── tasks.routes.ts             # Rutas de tareas
│   ├── deals.routes.ts             # Rutas de deals/pipeline
│   ├── properties.routes.ts        # Rutas de propiedades
│   ├── channels.routes.ts          # Conexiones de canales
│   ├── whatsapp.routes.ts          # WhatsApp específico
│   ├── flows.routes.ts             # Flow builder
│   ├── campaigns.routes.ts         # Campañas
│   ├── users.routes.ts             # Usuarios y roles
│   ├── company.routes.ts           # Configuración de empresa
│   ├── webhooks.routes.ts          # Webhooks externos
│   └── integrations.routes.ts      # Integraciones (Google, Calendly, etc.)
└── routes.ts                       # DEPRECATED - mantener por compatibilidad
```

## 📝 Plan de Implementación

### Fase 1: Preparación (1-2 días)
1. ✅ Crear directorio `server/routes/`
2. ✅ Crear `server/routes/index.ts` como router principal
3. ✅ Establecer convenciones y helpers compartidos

### Fase 2: Migración por Módulos (5-10 días)
Prioridad por impacto y frecuencia de cambios:

#### Alta Prioridad (migrar primero):
1. **tasks.routes.ts** - Tareas (acabamos de corregir bugs aquí)
2. **deals.routes.ts** - Pipeline/Deals (acabamos de corregir bugs aquí)
3. **contacts.routes.ts** - Contactos (core del negocio)
4. **messages.routes.ts** - Mensajes

#### Prioridad Media:
5. **conversations.routes.ts** - Conversaciones
6. **whatsapp.routes.ts** - WhatsApp
7. **flows.routes.ts** - Flow builder
8. **campaigns.routes.ts** - Campañas

#### Prioridad Baja (menos cambios):
9. **webhooks.routes.ts** - Webhooks
10. **integrations.routes.ts** - Integraciones
11. **users.routes.ts** - Usuarios
12. **company.routes.ts** - Configuración

### Fase 3: Limpieza (1 día)
1. Deprecar `routes.ts` original
2. Actualizar documentación
3. Revisar imports en toda la aplicación

## 🛠️ Helpers y Utilities Compartidos

Crear archivos de utilidades comunes:

```
server/routes/
├── middleware/
│   ├── auth.middleware.ts          # ensureAuthenticated, etc.
│   ├── permissions.middleware.ts   # requirePermission, etc.
│   └── validation.middleware.ts    # Validadores comunes
├── utils/
│   ├── response.utils.ts           # Respuestas estandarizadas
│   └── error-handler.utils.ts      # Manejo de errores
└── types/
    └── route-types.ts              # Tipos compartidos
```

## 📊 Beneficios Esperados

### Mantenibilidad
- ✅ Archivos < 500 líneas cada uno
- ✅ Código más fácil de leer y navegar
- ✅ Menor probabilidad de conflictos en git

### Desarrollo
- ✅ Más rápido encontrar rutas específicas
- ✅ Testing más sencillo (un módulo a la vez)
- ✅ Onboarding de nuevos desarrolladores más fácil

### Calidad
- ✅ Menos bugs por duplicación de código
- ✅ Más fácil aplicar patrones consistentes
- ✅ Code reviews más efectivos

## 🚀 Próximos Pasos

1. **Empezar con tasks.routes.ts** (ya conocemos bien este código)
2. Crear el archivo y mover las rutas de tareas
3. Probar que todo funciona
4. Continuar con deals.routes.ts
5. Iterar con el resto de módulos

## 📌 Notas Importantes

### Durante la Migración:
- Mantener `routes.ts` original funcionando
- Migrar un módulo completo a la vez
- Probar cada módulo después de migrar
- Actualizar tests si existen

### Convenciones:
- Un archivo = un dominio de negocio
- Prefijo consistente: `*.routes.ts`
- Exports nombrados para los routers
- Documentar cada grupo de rutas

---

**Fecha de creación**: 2026-01-13
**Autor**: Antigravity AI
**Estado**: Propuesta - Pendiente de aprobación
