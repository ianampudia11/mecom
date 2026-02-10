# 🐛 Storage.ts - Errores TypeScript Restantes

## ✅ Errores Corregidos (4/12)

1. ✅ Línea 6662: `getProperties()` - Fixed parameter type
2. ✅ Línea 6666: `getProperty()` - Fixed (ya no pasa companyId)
3. ✅ Línea 6674: `deleteProperty()` - Fixed parameter count
4. ✅ Línea 6684: `getDeals()` - Fixed (pasó objeto options)

---

## ⚠️ Errores Pendientes (8/12)

### 🔴 CRÍTICO - Métodos Faltantes

#### 1. Línea 6750: `getTasks` no existe
**Error**: `Property 'getTasks' does not exist`  
**Problema**: El repositorio solo tiene `getContactTasks(contactId)`  
**Solución**: Necesita crear `getAllTasks()` en el repositorio O usar lógica diferente

```typescript
// ACTUAL (MALO):
return tasksRepository.getAllTasks(options.companyId, options.filter);

// OPCIÓN 1 - Implementar en repositorio:
// Crear getAllTasks(companyId, filter) en tasks.repository.ts

// OPCIÓN 2 - Wrapper temporal:
async getTasks(options) {
  // Get all contact tasks for company
  const contacts = await this.getContacts({ companyId: options.companyId });
  const tasks = [];
  for (const contact of contacts) {
    const contactTasks = await tasksRepository.getContactTasks(contact.id);
    tasks.push(...contactTasks);
  }
  return tasks;
}
```

---

### 2. Líneas 6860, 6864: `published` → `publishedAt`
**Error**: Property 'published' does not exist  
**Problema**: Campo se llama `publishedAt` no `published`

**Fix rápido**:
```typescript
// Línea 6860:
publishedAt: published ? new Date() : null,

// Línea 6864:  
publishedAt: !article.publishedAt ? new Date() : null
```

---

### 3. Líneas 6926, 7101: `createContactAuditLog` no implementado
**Error**: Property does not exist  
**Problema**: Método nunca se implementó

**Opción 1 - Comentar**:
```typescript
// TODO: Implement audit logging
// await this.createContactAuditLog({...});
```

**Opción 2 - Implementar**:
Crear el método en DatabaseStorage

---

### 4. Línea 6981: `connectionId` → Field name wrong
**Error**: Property 'connectionId' does not exist  
**Problema**: Tabla emailConfigs usa `channelId` no `connectionId`

**Fix**:
```typescript
eq(emailConfigs.channelId, channelId)
```

---

### 5. Línea 7064: `getRolePermissionsByRole` no existe
**Error**: Property does not exist  
**Problema**: Método se llama `getRolePermissions`

**Fix**:
```typescript
return this.getRolePermissions(roleName);
```

---

### 6. Línea 7072: `createRolePermissions` no implementado
**Error**: Property does not exist

**Fix temporal**:
```typescript
// TODO: Implement role permissions creation
// await this.createRolePermissions(roleName, permissions);
return true;
```

---

### 7. Línea 7078: `companyId` no existe en tabla
**Error**: Property 'companyId' does not exist on partner_configurations  
**Problema**: Tabla no tiene ese campo

**Fix**:
```typescript
// partner_configurations doesn't have companyId
// Use a different filter or remove this condition
sql`1=1` // Remove filter temporarily
```

---

## 📊 Resumen

| Tipo de Error | Cantidad | Prioridad |
|---------------|----------|-----------|
| Parámetros incorrectos | 4 | ✅ CORREGIDO |
| Métodos faltantes | 4 | 🔴 CRÍTICO |
| Propiedades incorrectas | 4 | 🟡 MEDIUM |

---

## 🎯 Plan de Acción

### Inmediato (10 min):
1. Fix property names (`published`, `connectionId`)  
2. Comentar métodos no implementados
3. Fix method names (`getRolePermissionsByRole`)

### Corto plazo (30 min):
1. Implementar `getAllTasks()` en tasks repository
2. Implementar `createContactAuditLog()`  
3. Implementar `createRolePermissions()`

### Revisión (1 hora):
1. Revisar schema de `partner_configurations`
2. Decidir si companyId es necesario
3. Actualizar interfaz IStorage si es necesario

---

**Fecha**: 2026-01-13  
**Errores totales**: 12  
**Corregidos**: 4  
**Pendientes**: 8
