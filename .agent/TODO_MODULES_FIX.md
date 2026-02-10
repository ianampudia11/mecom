# 📋 TODO - Fix Permanente para Módulos

## 🎯 Deals Module - Mejora Pendiente

### Problema:
El `dealsModule` es demasiado simple y falta validación crítica.

### Acción Necesaria:
Copiar lógica completa de `routes.ts:16665-16836` al módulo de deals.

### Ubicación:
`server/modules/deals/routes/deals.routes.ts` línea 115

### Código a Copiar:
```typescript
// De: server/routes.ts líneas 16665-16836
// 1. Validación de contact
// 2. Mapeo de stages
// 3. Verificación de permisos de pipeline
// 4. Logging de actividades
// 5. Manejo de errores específicos
```

### Estimado:
20-30 minutos de trabajo

---

## ✅ Tags Module - COMPLETO

**Status**: Fixed ✅  
Se agregó la ruta GET /api/tags que faltaba.

---

## 🔄 Después de Fix de Deals:

1. Copiar lógica completa al módulo
2. Probar que funciona
3. Re-habilitar: `app.use('/api/deals', dealsModule);`
4. Eliminar ruta vieja de routes.ts (líneas 16665-16836)

**Beneficio**: -190 líneas de routes.ts

---

**Fecha**: 2026-01-13  
**Prioridad**: Media (funciona temporalmente con la ruta vieja)
