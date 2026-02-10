# 📁 Estructura del Proyecto CRM Plus

## 📊 Resumen General

Este es un sistema **CRM (Customer Relationship Management)** completo con:
- Frontend en **React + TypeScript**
- Backend en **Node.js + Express**
- Base de datos **PostgreSQL**
- Múltiples integraciones (WhatsApp, Email, Pagos, etc.)

---

## 🗂️ Estructura Principal del Proyecto

```
ianampudia11/
├── 📂 client/                          # Frontend de la aplicación
│   ├── 📂 public/                      # Archivos públicos estáticos
│   ├── 📂 src/                         # Código fuente del frontend
│   │   ├── App.tsx                     # Componente principal de la app
│   │   ├── main.tsx                    # Punto de entrada principal
│   │   ├── index.css                   # Estilos globales
│   │   ├── types.ts                    # Definiciones de tipos TypeScript
│   │   │
│   │   ├── 📂 components/              # Componentes React (302 archivos)
│   │   │   ├── UI Components           # Botones, Inputs, Cards, etc.
│   │   │   ├── Forms                   # Formularios reutilizables
│   │   │   ├── Modals                  # Diálogos y modales
│   │   │   ├── Tables                  # Tablas y listas
│   │   │   ├── Navigation              # Menús y navegación
│   │   │   ├── Chat                    # Componentes de chat
│   │   │   └── Dashboard               # Widgets del dashboard
│   │   │
│   │   ├── 📂 pages/                   # Páginas de la aplicación (61 archivos)
│   │   │   ├── Dashboard.tsx           # Página principal
│   │   │   ├── Contacts.tsx            # Gestión de contactos
│   │   │   ├── Deals.tsx               # Gestión de ventas
│   │   │   ├── Pipeline.tsx            # Vista de pipeline
│   │   │   ├── Inbox.tsx               # Mensajes/Chat
│   │   │   ├── Calendar.tsx            # Calendario
│   │   │   ├── Analytics.tsx           # Analítica
│   │   │   └── Settings.tsx            # Configuraciones
│   │   │
│   │   ├── 📂 hooks/                   # React Hooks personalizados (38 archivos)
│   │   │   ├── useContacts.ts          # Hook para contactos
│   │   │   ├── useDeals.ts             # Hook para tratos
│   │   │   ├── useAuth.ts              # Hook para autenticación
│   │   │   ├── useChat.ts              # Hook para chat
│   │   │   └── ...                     # Muchos más hooks
│   │   │
│   │   ├── 📂 contexts/                # Contextos de React (7 archivos)
│   │   │   ├── AuthContext.tsx         # Contexto de autenticación
│   │   │   ├── ThemeContext.tsx        # Contexto de tema
│   │   │   └── NotificationContext.tsx # Contexto de notificaciones
│   │   │
│   │   ├── 📂 services/                # Servicios para llamadas API (9 archivos)
│   │   │   ├── api.ts                  # Cliente API base
│   │   │   ├── contactsApi.ts          # API de contactos
│   │   │   ├── dealsApi.ts             # API de tratos
│   │   │   └── authApi.ts              # API de autenticación
│   │   │
│   │   ├── 📂 utils/                   # Utilidades y helpers (15 archivos)
│   │   │   ├── formatters.ts           # Formateo de datos
│   │   │   ├── validators.ts           # Validaciones
│   │   │   └── helpers.ts              # Funciones auxiliares
│   │   │
│   │   ├── 📂 lib/                     # Librerías compartidas (9 archivos)
│   │   ├── 📂 types/                   # Tipos TypeScript adicionales
│   │   └── 📂 styles/                  # Estilos adicionales
│   │
│   └── index.html                      # HTML base
│
├── 📂 server/                          # Backend de la aplicación
│   ├── index.ts                        # Servidor principal (17KB)
│   ├── routes.ts                       # Rutas principales (776KB) ⚠️
│   ├── storage.ts                      # Capa de almacenamiento (240KB)
│   ├── db.ts                          # Configuración de base de datos
│   ├── auth.ts                        # Autenticación (46KB)
│   ├── middleware.ts                  # Middlewares globales
│   ├── migration-system.ts            # Sistema de migraciones
│   │
│   ├── 📂 modules/                    # Módulos del backend (20 módulos)
│   │   │
│   │   ├── 📂 admin/                  # 👤 Administración del sistema
│   │   │   ├── routes.ts              # Rutas de admin
│   │   │   ├── service.ts             # Lógica de negocio
│   │   │   └── types.ts               # Tipos TypeScript
│   │   │
│   │   ├── 📂 analytics/              # 📊 Analítica y reportes
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 calendar/               # 📅 Gestión de calendario y citas
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 channels/               # 💬 Canales de comunicación
│   │   │   ├── routes.ts              # WhatsApp, Email, SMS, etc.
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 contacts/               # 👥 Gestión de contactos
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 deals/                  # 💰 Gestión de tratos/ventas
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 flows/                  # 🔄 Flujos de trabajo automatizados
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 integrations/           # 🔌 Integraciones externas
│   │   │   ├── routes.ts              # APIs de terceros
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 languages/              # 🌍 Internacionalización
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 messages/               # 📨 Sistema de mensajería
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 notes/                  # 📝 Notas
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 payments/               # 💳 Procesamiento de pagos
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 pipelines/              # 🎯 Pipelines de ventas
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 plans/                  # 📋 Planes de suscripción
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 properties/             # 🏠 Propiedades inmobiliarias
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 settings/               # ⚙️ Configuraciones del sistema
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 tags/                   # 🏷️ Sistema de etiquetas
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 tasks/                  # ✅ Gestión de tareas
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   ├── 📂 webhooks/               # 🔗 Webhooks
│   │   │   ├── routes.ts
│   │   │   ├── service.ts
│   │   │   └── types.ts
│   │   │
│   │   └── 📂 websites/               # 🌐 Generación de sitios web
│   │       ├── routes.ts
│   │       ├── service.ts
│   │       └── types.ts
│   │
│   ├── 📂 middleware/                 # Middlewares específicos (7 archivos)
│   │   ├── auth.middleware.ts         # Autenticación
│   │   ├── validation.middleware.ts   # Validación
│   │   └── error.middleware.ts        # Manejo de errores
│   │
│   ├── 📂 routes/                     # Rutas organizadas (25 archivos)
│   │   ├── Diferentes archivos para organizar las rutas del sistema
│   │
│   ├── 📂 services/                   # Servicios del backend (78 archivos)
│   │   ├── 📂 channels/               # Servicios de canales
│   │   │   ├── whatsapp.service.ts
│   │   │   ├── email.service.ts
│   │   │   └── sms.service.ts
│   │   └── 📂 document-processors/    # Procesadores de documentos
│   │       ├── pdf.processor.ts
│   │       └── image.processor.ts
│   │
│   ├── 📂 types/                      # Tipos TypeScript del backend (3 archivos)
│   ├── 📂 utils/                      # Utilidades del backend (16 archivos)
│   ├── 📂 widgets/                    # Widgets (3 archivos)
│   └── 📂 test/                       # Pruebas (2 archivos)
│
├── 📂 shared/                         # Código compartido frontend/backend
│   └── 📂 types/                      # Tipos TypeScript compartidos
│       ├── user.types.ts
│       ├── contact.types.ts
│       └── deal.types.ts
│
├── 📂 migrations/                     # Migraciones de base de datos (86 archivos)
│   ├── 001-initial-schema.sql
│   ├── 002-add-whatsapp.sql
│   ├── 003-add-tags.sql
│   └── ...
│
├── 📂 scripts/                        # Scripts de utilidad (61 archivos)
│   ├── 📂 debug/                      # Scripts de debug
│   ├── 📂 database/                   # Scripts de BD
│   ├── 📂 setup/                      # Scripts de configuración
│   └── 📂 maintenance/                # Scripts de mantenimiento
│
├── 📂 translations/                   # Traducciones (3 archivos)
│   ├── es.json                       # Español
│   ├── en.json                       # Inglés
│   └── pt.json                       # Portugués
│
├── 📂 public/                         # Archivos públicos del servidor
│
├── 📂 uploads/                        # Archivos subidos por usuarios
│   └── 📂 webchat/                    # Archivos del webchat
│
├── 📂 media/                          # Archivos multimedia
│   └── 📂 temp/                       # Archivos temporales
│
├── 📂 whatsapp-sessions/              # Sesiones de WhatsApp
│   └── session-*.json                 # Credenciales de sesión
│
├── 📂 backups/                        # Respaldos del sistema
│
├── 📂 dist/                           # Build de producción
│   └── 📂 public/
│       ├── 📂 assets/                 # CSS, JS compilados
│       └── 📂 uploads/
│
├── 📂 node_modules/                   # Dependencias de Node.js
│
├── 📂 .agent/                         # Configuración del agente
│
└── 📂 .git/                           # Repositorio Git
```

---

## 📄 Archivos de Configuración Raíz

### 📦 Gestión de Paquetes
- **`package.json`** - Dependencias y scripts npm (8KB)
- **`package-lock.json`** - Lockfile de dependencias (832KB)

### 🔧 Configuración TypeScript
- **`tsconfig.json`** - Configuración de TypeScript
- **`tsx.config.json`** - Configuración de tsx

### ⚡ Build Tools
- **`vite.config.ts`** - Configuración de Vite (build tool)
- **`vitest.config.ts`** - Configuración de tests
- **`postcss.config.js`** - Configuración de PostCSS

### 🎨 Estilos
- **`tailwind.config.ts`** - Configuración de Tailwind CSS (3KB)
- **`theme.json`** - Tema personalizado

### 🔍 Calidad de Código
- **`eslint.config.js`** - Configuración de ESLint
- **`.gitignore`** - Archivos ignorados por Git

### 🌍 Variables de Entorno
- **`.env`** - Variables de entorno (713 bytes)
- **`.env.local`** - Variables locales
- **`.env.development`** - Variables de desarrollo (903 bytes)
- **`.env.example`** - Ejemplo de variables (3.4KB)
- **`.env.template`** - Plantilla de variables (4KB)

### 🐳 Docker
- **`Dockerfile`** - Dockerfile principal (2.9KB)
- **`Dockerfile.deploy`** - Dockerfile de deploy (868 bytes)
- **`Dockerfile.simple`** - Dockerfile simplificado (1.3KB)
- **`docker-compose.yml`** - Docker Compose principal (1.9KB)
- **`docker-compose.dev.yml`** - Docker Compose desarrollo (731 bytes)
- **`docker-compose.template.yml`** - Plantilla Docker Compose (5KB)
- **`docker-entrypoint.sh`** - Script de entrada (3.1KB)
- **`docker-entrypoint-deploy.sh`** - Script de entrada deploy
- **`docker-entrypoint-simple.sh`** - Script de entrada simple
- **`.dockerignore`** - Archivos ignorados por Docker

### 🗄️ Base de Datos
- **`drizzle.config.js`** - Configuración de Drizzle ORM
- **`drizzle.config.ts`** - Configuración TypeScript de Drizzle
- **`init-db.sql`** - Inicialización de base de datos
- **`init-schema.sql`** - Schema inicial (2.7KB)

### 🚀 Deploy
- **`deploy.sh`** - Script de despliegue completo (26KB)
- **`start.js`** - Script de inicio (1.3KB)

---

## 🔧 Scripts de Utilidad en Raíz

### 🐛 Scripts de Debug
- `debug-deals.ts` - Debug de tratos
- `debug-pipelines.ts` - Debug de pipelines (2.7KB)
- `debug-migration.ts` - Debug de migraciones
- `debug-get-deals.ts` - Debug de obtención de tratos
- `debug-deal-props.ts` - Debug de propiedades
- `debug-hidden-deal.ts` - Debug de tratos ocultos (1.6KB)
- `debug-props.ts` - Debug de propiedades
- `find-error-source.ts` - Encontrar fuente de error

### 🗄️ Scripts de Base de Datos
- `check-db-schema.ts` - Verificar schema de BD
- `check_db.ts` - Verificar BD
- `run-migration.ts` - Ejecutar migraciones (2.5KB)
- `make_contact_id_nullable.ts` - Hacer contactId nullable
- `create_media_table.ts` - Crear tabla de media
- `add_checklist_column.ts` - Añadir columna checklist
- `add_contact_assignee.ts` - Añadir asignado de contacto

### ⚙️ Scripts de Configuración
- `seed-all.ts` - Poblar base de datos (4.8KB)
- `seed-test-data.sql` - Datos de prueba (1.8KB)
- `enable-registration.ts` - Habilitar registro
- `enable-registration.sql` - SQL para habilitar registro
- `check-registration.ts` - Verificar registro
- `update-branding.ts` - Actualizar branding (1.4KB)
- `verify-data.ts` - Verificar datos (2.2KB)

### 🔨 Scripts de Reparación
- `fix-broken-stage.ts` - Reparar stage roto
- `fix-pipeline-stages.ts` - Reparar stages de pipeline (2.1KB)
- `fix-trigger.ts` - Reparar trigger (1KB)
- `fix_index.js` - Reparar índice
- `fix_index.cjs` - Reparar índice (CommonJS)
- `fix_storage.cjs` - Reparar storage
- `repair_index.js` - Reparar índice (1.1KB)
- `repair_index.cjs` - Reparar índice (1.5KB)

### 🧪 Scripts de Testing
- `create-test-deal.ts` - Crear trato de prueba (2.4KB)
- `test-deal-creation.ps1` - Test de creación de trato

### 🛠️ Otros Scripts
- `disable-trigger.ts` - Deshabilitar trigger
- `get-trigger-source.ts` - Obtener fuente de trigger
- `find-deals-line.ts` - Encontrar línea de deals
- `find-deals-line.js` - Encontrar línea (JS)
- `generate-hash.js` - Generar hash
- `clean_storage.py` - Limpiar storage (Python)

---

## 📊 Carpeta scripts/ (61 archivos)

La carpeta `scripts/` contiene scripts adicionales organizados por categoría:
- Scripts de migración
- Scripts de backup
- Scripts de deploy
- Scripts de testing
- Scripts de mantenimiento
- Y más...

---

## 📈 Estadísticas del Proyecto

### Frontend (client/)
| Categoría | Cantidad |
|-----------|----------|
| Componentes | 302+ |
| Páginas | 61 |
| Hooks | 38 |
| Servicios | 9 |
| Contextos | 7 |
| Utilidades | 15 |
| Librerías | 9 |

### Backend (server/)
| Categoría | Cantidad |
|-----------|----------|
| Módulos | 20 |
| Servicios | 78 |
| Rutas | 25 archivos |
| Middlewares | 7 |
| Tipos | 3 |
| Utilidades | 16 |

### General
| Categoría | Cantidad |
|-----------|----------|
| Migraciones BD | 86 |
| Scripts totales | 61+ en scripts/ + extras en raíz |
| Traducciones | 3 idiomas |

---

## 🛠️ Stack Tecnológico

### 🎨 Frontend
| Tecnología | Propósito |
|------------|-----------|
| **React 18** | Librería de UI |
| **TypeScript** | Tipado estático |
| **Vite** | Build tool ultrarrápido |
| **Tailwind CSS** | Framework de CSS |
| **React Router** | Navegación |
| **React Query** | Gestión de estado servidor |
| **Axios** | Cliente HTTP |
| **Socket.io-client** | WebSockets en tiempo real |

### ⚙️ Backend
| Tecnología | Propósito |
|------------|-----------|
| **Node.js** | Runtime de JavaScript |
| **Express.js** | Framework web |
| **TypeScript** | Tipado estático |
| **PostgreSQL** | Base de datos relacional |
| **Drizzle ORM** | ORM para TypeScript |
| **Socket.io** | WebSockets |
| **Passport.js** | Autenticación |
| **bcrypt** | Hash de contraseñas |

### 🗄️ Base de Datos
| Tecnología | Propósito |
|------------|-----------|
| **PostgreSQL** | Base de datos principal |
| **Drizzle ORM** | ORM TypeScript-first |
| **pg** | Driver de PostgreSQL |

### 🐳 DevOps
| Tecnología | Propósito |
|------------|-----------|
| **Docker** | Contenedores |
| **Docker Compose** | Orquestación |
| **Git** | Control de versiones |
| **Bash/PowerShell** | Scripts de deploy |

### 🔌 Integraciones
| Servicio | Funcionalidad |
|----------|---------------|
| **WhatsApp Business API** | Mensajería |
| **Gmail/SMTP** | Email |
| **Google Calendar** | Calendario |
| **Stripe/PayPal** | Pagos |
| **n8n** | Automatización |
| **OpenAI** | IA y chatbots |
| **Webhooks** | Integraciones custom |

---

## 📋 Módulos del Backend Detallado

### 1. 👤 **admin** - Administración
- Gestión de usuarios del sistema
- Permisos y roles
- Configuración global

### 2. 📊 **analytics** - Analítica
- Reportes de ventas
- Métricas de conversión
- Dashboard analítico
- Exportación de datos

### 3. 📅 **calendar** - Calendario
- Gestión de citas
- Sincronización con Google Calendar
- Recordatorios
- Disponibilidad de agentes

### 4. 💬 **channels** - Canales
- WhatsApp Business
- Email (SMTP/Gmail)
- SMS
- Facebook Messenger
- Webchat
- Telegram

### 5. 👥 **contacts** - Contactos
- CRUD de contactos
- Importación/Exportación CSV
- Segmentación
- Historial de interacciones
- Campos personalizados

### 6. 💰 **deals** - Tratos/Ventas
- Gestión de oportunidades
- Pipeline de ventas
- Etapas personalizables
- Conversión de leads
- Propiedades de deals

### 7. 🔄 **flows** - Flujos de Trabajo
- Automatizaciones
- Flujos de conversación
- Respuestas automáticas
- Integración con n8n
- Disparadores y acciones

### 8. 🔌 **integrations** - Integraciones
- APIs de terceros
- Webhooks entrantes/salientes
- OAuth
- Conectores personalizados

### 9. 🌍 **languages** - Idiomas
- Internacionalización (i18n)
- Traducciones dinámicas
- Soporte multi-idioma
- Idiomas: ES, EN, PT

### 10. 📨 **messages** - Mensajería
- Bandeja de entrada unificada
- Chat en tiempo real
- Adjuntos de archivos
- Mensajes masivos
- Plantillas de mensajes

### 11. 📝 **notes** - Notas
- Notas de contactos
- Notas de deals
- Colaboración en equipo
- Historial de notas

### 12. 💳 **payments** - Pagos
- Procesamiento de pagos
- Integración con Stripe
- Integración con PayPal
- Historial de transacciones
- Facturación

### 13. 🎯 **pipelines** - Pipelines
- Creación de pipelines
- Etapas personalizadas
- Arrastrar y soltar deals
- Métricas por pipeline
- Múltiples pipelines

### 14. 📋 **plans** - Planes
- Planes de suscripción
- Gestión de límites
- Features por plan
- Upgrades/Downgrades

### 15. 🏠 **properties** - Propiedades
- Gestión de propiedades inmobiliarias
- Galería de imágenes
- Características de propiedades
- Búsqueda de propiedades

### 16. ⚙️ **settings** - Configuraciones
- Configuración de cuenta
- Branding (logo, colores)
- Configuración de canales
- Preferencias de usuario
- Configuración de empresa

### 17. 🏷️ **tags** - Etiquetas
- Creación de tags
- Asignación a contactos/deals
- Filtrado por tags
- Estadísticas de tags
- Tags compartidos

### 18. ✅ **tasks** - Tareas
- Gestión de tareas
- Asignación de tareas
- Prioridades
- Fechas de vencimiento
- Categorías de tareas
- Checklist

### 19. 🔗 **webhooks** - Webhooks
- Configuración de webhooks
- Eventos disparadores
- Retry logic
- Logs de webhooks
- Webhooks personalizados

### 20. 🌐 **websites** - Sitios Web
- Generación de landing pages
- Formularios de captura
- Integración con CRM
- Páginas personalizables

---

## 📝 Archivos de Log

> **Nota:** Estos archivos NO deberían estar en el repositorio Git

- `startup.log` - Log de inicio del servidor (12KB)
- `server-error.log` - Errores del servidor (3KB)
- `migration-error.log` - Errores de migraciones
- `backup_error.log` - Errores de backup
- `tsc.log` - Log de compilación TypeScript (122KB)
- `tsc_check.log` - Verificación de TypeScript (360KB)
- Múltiples logs de debug y verificación

---

## 🚨 Observaciones y Recomendaciones

### ⚠️ Archivos Grandes
1. **`server/routes.ts` (776KB)** - Archivo demasiado grande
   - **Problema:** Difícil de mantener y debuguear
   - **Solución:** Refactorizar en múltiples archivos por módulo

2. **`server/storage.ts` (240KB)** - Otro archivo muy grande
   - **Problema:** Mezla demasiada lógica de negocio
   - **Solución:** Separar por entidades (ContactStorage, DealStorage, etc.)

### 📦 Archivos que NO deberían estar en el repositorio
- Archivos `.log` (deberían estar en `.gitignore`)
- Archivos `.tar.gz` de backup (ya están ignorados)
- Carpeta `backups/` (ya está ignorada)

### ✅ Buenas Prácticas Implementadas
1. ✨ **Arquitectura modular** en `server/modules/`
2. ✨ **Separación frontend/backend** clara
3. ✨ **TypeScript** en todo el proyecto
4. ✨ **Sistema de migraciones** robusto
5. ✨ **Docker** para deployment
6. ✨ **Múltiples entornos** (.env.development, .env.local)

### 🎯 Mejoras Sugeridas
1. **Refactorizar** `routes.ts` en archivos más pequeños
2. **Limpiar** archivos de log del repositorio
3. **Documentar** cada módulo individualmente
4. **Agregar tests** (existen configuraciones pero pocos tests)
5. **README.md** principal del proyecto
6. **CHANGELOG.md** para tracking de cambios

---

## 🔗 Flujo de Datos

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│  Frontend (React + TypeScript)  │
│  Puerto: 5173 (dev) / 80 (prod) │
└────────────┬────────────────────┘
             │
             │ API REST / WebSocket
             ▼
┌─────────────────────────────────┐
│   Backend (Express + Node.js)   │
│   Puerto: 3000 / 5000            │
│                                  │
│  ┌──────────────────────────┐   │
│  │   routes.ts (Rutas)      │   │
│  └────────┬─────────────────┘   │
│           │                      │
│           ▼                      │
│  ┌──────────────────────────┐   │
│  │  Módulos (20 módulos)    │   │
│  │  - admin, deals, etc.    │   │
│  └────────┬─────────────────┘   │
│           │                      │
│           ▼                      │
│  ┌──────────────────────────┐   │
│  │  storage.ts (DB Layer)   │   │
│  └────────┬─────────────────┘   │
└───────────┼─────────────────────┘
            │
            ▼
┌─────────────────────────────────┐
│      PostgreSQL Database        │
│      Puerto: 5432               │
└─────────────────────────────────┘
```

---

## 🚀 Comandos Principales

```bash
# Desarrollo
npm run dev              # Inicia frontend + backend en modo desarrollo

# Build
npm run build            # Compila el proyecto para producción

# Base de datos
npm run db:migrate       # Ejecuta migraciones
npm run db:seed          # Pobla la base de datos

# Docker
docker-compose up        # Inicia todo con Docker
docker-compose up -d     # Inicia en background

# Limpieza
npm run clean            # Limpia archivos generados
```

---

## 📚 Documentación Adicional

Para más información sobre módulos específicos, consulta:
- `client/README.md` (si existe)
- `server/README.md` (si existe)
- Documentación de cada módulo en `server/modules/[modulo]/README.md`

---

**Última actualización:** 12 de enero de 2026

**Generado automáticamente** - Si encuentras algún error o desactualización, por favor actualiza este documento.
