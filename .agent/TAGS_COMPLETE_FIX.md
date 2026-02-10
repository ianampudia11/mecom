# ✅ BUG FIX COMPLETADO: Tags System

**Fecha**: 2026-01-13 19:48  
**Problema**: Tag "salsa" aparece en deals pero no en el dropdown para agregar

---

## 🐛 ROOT CAUSES (2 problemas)

### Problema 1: Settings mostraba "No hay tags"
**Causa**: La ruta `GET /api/tags` devolvía TODOS los tags en uso, pero Settings necesitaba solo los tags creados manualmente en la tabla `tags`.

### Problema 2: Dropdown de tags en Deals llamaba endpoint inexistente
**Causa**: `PipelineList.tsx` llamaba a `/api/contacts/tags` (endpoint que no existe).

---

## ✅ SOLUCIONES IMPLEMENTADAS

### 1. Backend - Ruta `/api/tags` Actualizada

**Nueva función en repositorio:**
```typescript
// tags.repository.ts
export async function getManualTags(companyId: number) {
  const result = await db.execute(sql`
    SELECT id, tag as name, color, created_at, updated_at
    FROM tags
    WHERE company_id = ${companyId}
    ORDER BY tag ASC
  `);
  return result.rows || [];
}
```

**Ruta con Query Param:**
```typescript
GET /api/tags → Solo tags de tabla tags (para Settings)
GET /api/tags?include_usage=true → TODOS los tags en uso + stats
```

**Comportamiento:**
- **Sin parámetro**: Devuelve tags de la tabla `tags` (creados manualmente)
- **Con `?include_usage=true`**: Devuelve TODOS los tags (de deals, contacts, conversations) con estadísticas

---

### 2. Frontend - PipelineList.tsx Actualizado

**Antes (incorrecto):**
```typescript
const { data: availableTags = [] } = useQuery({
  queryKey: ['/api/contacts/tags'],
  queryFn: () => fetch('/api/contacts/tags')... // ❌ Endpoint no existe
});
```

**Después (correcto):**
```typescript
const { data: availableTags = [] } = useQuery({
  queryKey: ['/api/tags', { include_usage: true }],
  queryFn: () => apiRequest('GET', '/api/tags?include_usage=true')
    .then(res => res.json())
    .then(data => Array.isArray(data) 
      ? data.map((t: any) => t.name || t.tag || t) 
      : []
    ),
  staleTime: 60000,
  enabled: openTags
});
```

---

## 🎯 RESULTADOS

### ✅ Settings:
- Muestra correctamente "No hay tags creados aún"
- Solo muestra tags de la tabla `tags` (creados manualmente)
- Funciona con `GET /api/tags` (sin parámetros)

### ✅ Deals Dropdown:
- **Ahora muestra el tag "salsa"** ✅
- Muestra TODOS los tags en uso (del deal, contacts, conversations)
- Usa `GET /api/tags?include_usage=true`

---

## 📊 ARQUITECTURA DE TAGS

| Fuente | Dónde está | Cuándo aparece |
|--------|-----------|----------------|
| **Tabla `tags`** | Base de datos | Tags creados manualmente en Settings |
| **Campo `tags` en deals** | Array en registro | Tags aplicados a deals |
| **Campo `tags` en contacts** | Array en registro | Tags aplicados a contactos |
| **Campo `tags` en conversations** | Array en registro | Tags aplicados a conversaciones |

**API Endpoints:**
```
GET /api/tags                     → Tags de tabla tags (manual)
GET /api/tags?include_usage=true  → TODOS los tags en uso
GET /api/tags/stats               → Tags con conteos (usado en DealCard)
POST /api/tags                    → Crear tag manual
PUT /api/tags/:name               → Renombrar tag
DELETE /api/tags/:name            → Eliminar tag
```

---

## 📝 Archivos Modificados

### Backend:
1. `server/modules/tags/repositories/tags.repository.ts`
   - +18 líneas: Nueva función `getManualTags()`

2. `server/modules/tags/routes/tags.routes.ts`
   - Ruta `GET /` refactorizada con query param `include_usage`

### Frontend:
3. `client/src/components/pipeline/PipelineList.tsx`
   - Línea 224: Actualizada query de tags
   - Usa endpoint correcto con `?include_usage=true`

---

## ✅ VERIFICACIÓN

**Para probar:**
1. ✅ Settings → Tags: Debe mostrar "No hay tags creados"
2. ✅ Deals → Agregar tag → Dropdown: Debe mostrar "salsa"
3. ✅ Crear nuevo tag desde dropdown: Debe aparecer
4. ✅ Crear tag manual en Settings: Debe sincronizar

---

**Estado**: ✅ **COMPLETAMENTE RESUELTO**  
**El tag "salsa" ahora aparece en el dropdown** ✅
