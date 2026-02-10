# 📋 Plan de Subdivisión de routes.ts

## 🎯 Objetivo
Reducir `routes.ts` de **17,947 líneas** a **~500 líneas** mediante:
1. ✅ Eliminar código duplicado de módulos existentes
2. 🆕 Mover secciones grandes a nuevos archivos modulares
3. 🔄 Reorganizar código duplicado disperso

---

## 📊 Análisis de Contenido Actual

### Secciones Identificadas en routes.ts

#### ✅ **Ya tienen módulo** (solo eliminar duplicados):
1. **Tasks** - `/api/tasks` → `server/modules/tasks/` ✅ PARCIALMENTE LIMPIADO
2. **Deals** - `/api/deals` → `server/modules/deals/` ✅ PARCIALMENTE LIMPIADO
3. **Contacts** - `/api/contacts` → `server/modules/contacts/`
4. **Properties** - `/api/properties` → `server/modules/properties/`
5. **Messages** - `/api/messages` → `server/modules/messages/`
6. **Flows** - `/api/flows` → `server/modules/flows/`
7. **Pipelines** - `/api/pipelines` → `server/modules/pipelines/`
8. **Notes** - `/api/notes` → `server/modules/notes/`
9. **Tags** - `/api/tags` → `server/modules/tags/` ⚠️ Código en líneas 210-532
10. **Settings** - `/api/settings` → `server/modules/settings/`
11. **Channels** - `/api/channels` → `server/modules/channels/`
12. **Analytics** - `/api/analytics` → `server/modules/analytics/`
13. **Websites** - `/api/websites` → `server/modules/websites/`
14. **Integrations** - `/api/integrations` → `server/modules/integrations/`
15. **Webhooks** - `/api/webhooks` → `server/modules/webhooks/`

#### 🆕 **Necesitan archivo nuevo** (crear y mover):
16. **Conversations** - `/api/conversations/*` → `server/routes/conversations.ts` (GRANDE ~800 líneas)
17. **WhatsApp** - `/api/whatsapp/*` → Ya existe `server/routes/whatsapp-templates.ts` pero hay más código
18. **Channel Connections** - `/api/channel-connections/*` → Mover a módulo channels
19. **Users/Team** - `/api/users/*`, `/api/team/*` → `server/routes/users.ts`
20. **Company Settings** - `/api/company-*` → Consolidar en settings
21. **Google Calendar** - `/api/google/*` → `server/routes/google-calendar.ts`
22. **Zoho Calendar** - `/api/zoho/*` → `server/routes/zoho-calendar.ts`
23. **Calendly** - `/api/calendly/*` → `server/routes/calendly.ts`
24. **API Keys** - `/api/settings/api-keys` → Ya está pero verificar
25. **Flow Sessions** - `/api/sessions/*` → Parte de flows module
26. **Messenger** - `/api/messenger/*` → Parte de channels
27. **Instagram** - `/api/instagram/*` → Parte de channels
28. **TikTok** - `/api/tiktok/*` → Parte de channels
29. **Email** - `/api/email/*` → Parte de channels
30. **Webchat** - `/api/webchat/*` → Parte de channels

#### 📝 **Código Misceláneo** (analizar caso por caso):
31. Public routes (`/public/*`)
32. Partner configurations
33. Bot status endpoints
34. Upload endpoints
35. Backup/restore endpoints

---

## 🚀 Plan de Acción - Fase 1 (Hoy)

### Paso 1: Limpiar Tags (10 min)
**Ubicación**: Líneas 210-532 (~320 líneas)
**Acción**: Eliminar, ya existe `tagsModule` en línea 714
**Impacto**: -320 líneas

### Paso 2: Mover Conversations a Archivo Nuevo (30 min)
**Estimado**: ~800-1000 líneas
**Crear**: `server/routes/conversations.ts`
**Rutas a mover**:
- GET `/api/conversations`
- GET `/api/conversations/:id`
- POST `/api/conversations/:id/mark-read`
- GET `/api/conversations/unread-counts`
- POST `/api/conversations/whatsapp/initiate`
- etc.

### Paso 3: Limpiar Contacts Duplicados (20 min)
**Acción**: Verificar qué está en `contactsModule` y eliminar duplicados
**Estimado**: -400 líneas

### Paso 4: Limpiar Properties, Pipelines, Flows (30 min)
**Acción**: Eliminar código duplicado de módulos existentes
**Estimado**: -600 líneas

---

## 📈 Progreso Esperado Hoy

| Paso | Archivo/Sección | Líneas a Eliminar |
|------|----------------|-------------------|
| ✅ Ya hecho | Tasks + Deals | -444 |
| 1 | Tags | -320 |
| 2 | Conversations (mover) | -800 |
| 3 | Contacts | -400 |
| 4 | Properties/Pipelines/Flows | -600 |
| **TOTAL** | | **-2,564 líneas** |

**Resultado esperado**: routes.ts de **17,947 → ~15,383 líneas** (-14%)

---

## 🎯 Plan de Acción - Fase 2 (Mañana)

### Crear Archivos Modulares Grandes:
1. `server/routes/whatsapp-extended.ts` - Rutas WhatsApp adicionales (~1,500 líneas)
2. `server/routes/channel-management.ts` - Channel connections (~800 líneas)
3. `server/routes/integrations-calendar.ts` - Google/Zoho/Calendly (~600 líneas)
4. `server/routes/users-team.ts` - User management (~400 líneas)

**Estimado Fase 2**: -3,300 líneas → routes.ts llegaría a **~12,000 líneas**

---

## 🎯 Plan de Acción - Fase 3 (Futuro)

### Consolidar y Optimizar:
1. Verificar TODOS los módulos existentes
2. Eliminar TODO el código duplicado restante
3. Mover rutas públicas a archivo separado
4. Reorganizar imports y middlewares

**Objetivo Final**: routes.ts con **500-800 líneas**

---

## 📝 Estructura Final Propuesta

```
server/
├── routes.ts (500-800 líneas) ← SOLO setup y mounting
├── routes/
│   ├── conversations.ts (800 líneas) 🆕
│   ├── whatsapp-extended.ts (1,500 líneas) 🆕
│   ├── channel-management.ts (800 líneas) 🆕
│   ├── integrations-calendar.ts (600 líneas) 🆕
│   ├── users-team.ts (400 líneas) 🆕
│   ├── public-routes.ts (300 líneas) 🆕
│   └── [22 archivos existentes]
└── modules/
    ├── tasks/ ✅
    ├── deals/ ✅
    ├── contacts/ ✅
    └── [16 módulos existentes]
```

---

## ✅ Siguiente Paso INMEDIATO

**¿Qué quieres hacer primero?**

**Opción A**: Eliminar Tags duplicados (rápido, 10 minutos, -320 líneas)
**Opción B**: Crear `conversations.ts` y mover todo lo relacionado (30 min, -800 líneas)
**Opción C**: Hacer limpieza masiva de todos los módulos existentes (1 hora, -1,800 líneas)

---

**Fecha**: 2026-01-13  
**Estado actual**: 17,947 líneas (ya limpiamos 444)  
**Próximo objetivo**: 15,383 líneas (-14%)
