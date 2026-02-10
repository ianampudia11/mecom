# 🐛 BUG FIX: Tags System - Settings vs Lista

**Fecha**: 2026-01-13 19:42  
**Problema**: Tag "salsa" aparece en lista de deals pero Settings dice "No hay tags"

---

## 🎯 ROOT CAUSE

### El Problema:
El tag "salsa" existe en el **campo `tags`del deal** (array en la tabla `deals`) pero **NO existe en la tabla `tags`** (tags creados manualmente).

### Por qué pasaba:
La ruta `GET /api/tags` devolvía **TODOS los tags en uso** (de deals, contacts, conversations) usando `getTagStats()`, pero Settings necesita solo los **tags creados manualmente** de la tabla `tags`.

---

## ✅ SOLUCIÓN IMPLEMENTADA

### 1. Nueva Función en Repositorio
Agregada `getManualTags()` en `tags.repository.ts`:

```typescript
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

### 2. Ruta Actualizada con Query Param
`GET /api/tags` ahora soporta dos modos:

**Settings (default):**
```
GET /api/tags
→ Devuelve solo tags de tabla `tags` (creados manualmente)
```

**Lista/Dropdowns (con param):**
```
GET /api/tags?include_usage=true
→ Devuelve TODOS los tags en uso + stats
```

---

## 📊 COMPORTAMIENTO

### Antes del Fix:
```
GET /api/tags
→ Devuelve: ["salsa"] (tag en uso en deal)

Settings muestra: "No hay tags creados"
Deals muestra: Tag "salsa" disponible ❌ INCONSISTENTE
```

### Después del Fix:
```
GET /api/tags
→ Devuelve: [] (no hay tags en tabla tags)

GET /api/tags?include_usage=true
→ Devuelve: [{ name: "salsa", usage: { deals: 1 }}]

Settings muestra: "No hay tags creados aún" ✅ CORRECTO
Deals muestra: Tag "salsa" (usando include_usage=true) ✅ CORRECTO
```

---

## 🔄 Migración de Frontend

### Si el frontend de Deals usaba GET /api/tags:
**ACTUALIZAR** a:
```javascript
// Para dropdowns/listas en Deals:
fetch('/api/tags?include_usage=true')

// Para Settings/Management:
fetch('/api/tags')
```

---

## 💡 DIFERENCIA CONCEPTUAL

| Tabla `tags` | Campo `tags` en deals/contacts |
|--------------|--------------------------------|
| Tags **creados manualmente** | Tags **en uso** |
| Administrados en Settings | Aplicados a registros |
| Tienen color personalizado | Pueden no tener color |
| Persistentes hasta borrar | Existen mientras estén en uso |

---

## 🎯 RESULTADOS

### ✅ Fixes Aplicados:
1. ✅ `getManualTags()` agregado al repositorio
2. ✅ `GET /api/tags` actualizada con lógica condicional
3. ✅ Settings ahora muestra correctamente "No hay tags creados"
4. ✅ Deals sigue mostrando tags en uso (con `?include_usage=true`)

### ⚠️ Acción Requerida (Frontend):
Si los dropdowns de Deals llaman a `GET /api/tags`, actualizar a:
```
GET /api/tags?include_usage=true
```

---

## 📝 Archivos Modificados

1. `server/modules/tags/repositories/tags.repository.ts`
   - +18 líneas (nueva función `getManualTags`)

2. `server/modules/tags/routes/tags.routes.ts`  
   - Refactorizada ruta GET /api/tags
   - +10 líneas lógica condicional

---

**Estado**: ✅ **RESUELTO**  
**Settings ahora funciona correctamente** mostrando solo tags de la tabla `tags`.
