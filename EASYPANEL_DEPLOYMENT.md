# Guía de Despliegue en EasyPanel

Esta guía te ayudará a desplegar **iawarrior-tech** en tu servidor usando EasyPanel.

## Requisitos Previos

1.  Acceso a tu panel de EasyPanel.
2.  El código fuente subido a un repositorio Git (GitHub, GitLab, etc.).
3.  Un servicio de PostgreSQL creado en EasyPanel (ya lo tienes configurado).

## Paso 1: Preparar el Repositorio

Asegúrate de que los siguientes archivos estén en la raíz de tu repositorio:
- `Dockerfile.easypanel` (El archivo que acabamos de crear)
- `package.json`

> **Nota**: No es necesario subir la carpeta `dist/` ni `node_modules/`, ya que EasyPanel construirá la aplicación.

## Paso 2: Crear el Proyecto en EasyPanel

1.  Entra a EasyPanel.
2.  Crea un nuevo **Project** (o usa uno existente).
3.  Dentro del proyecto, haz clic en **+ Service** y selecciona **App**.

## Paso 3: Configurar la Fuente (Source)

1.  En la configuración del servicio, ve a la pestaña **Source**.
2.  Conecta tu repositorio de GitHub/GitLab.
3.  Selecciona el repositorio `ianampudia11/mecom`.
4.  Rama: `main` (o la rama que uses para producción).

## Paso 4: Configurar el Build

1.  Ve a la pestaña **Build**.
2.  **Build Method**: Selecciona `Dockerfile`.
3.  **Dockerfile Path**: Escribe `/Dockerfile.easypanel`.
    *   *Importante*: Asegúrate de escribir el nombre exacto del archivo que creamos. Si no puedes especificar el nombre y solo te deja elegir la ruta, tendrás que renombrar `Dockerfile.easypanel` a `Dockerfile` en tu repositorio antes de desplegar.

## Paso 5: Variables de Entorno (Environment)

1.  Ve a la pestaña **Environment**.
2.  Copia y pega el contenido del archivo `.env.easypanel` que hemos preparado.
3.  **IMPORTANTE**: Actualiza los valores, especialmente:
    *   `DATABASE_URL`: Usa la contraseña real de tu base de datos PostgreSQL.
        *   Formato: `postgresql://postgres:CONTRASEÑA@aplicar_postgres:5432/aplicar`
    *   `SUPER_ADMIN_PASSWORD`: Define una contraseña segura.
    *   `SESSION_SECRET`: Escribe una cadena aleatoria.

## Paso 6: Configurar Dominios

1.  Ve a la pestaña **Domains**.
2.  Añade tu dominio: `cr.ianampudia.com`.
3.  Habilita HTTPS (EasyPanel suele gestionar los certificados SSL automáticamente con Let's Encrypt).
4.  Puerto del contenedor: `9000`.

## Paso 7: Desplegar

1.  Haz clic en **Deploy**.
2.  Ve a la pestaña **Deployments** para ver los logs de construcción.
3.  El proceso puede tardar unos minutos la primera vez mientras instala dependencias y construye la aplicación.

## Paso 8: Verificar y Finalizar

1.  Una vez que el despliegue esté en verde ("Running").
2.  Abre `https://cr.ianampudia.com` en tu navegador.
3.  Deberías ver la pantalla de inicio de sesión.
4.  Ingresa con:
    *   Email: `admin@ianampudia.com` (o el que hayas puesto en `SUPER_ADMIN_EMAIL`)
    *   Password: La contraseña que pusiste en `SUPER_ADMIN_PASSWORD`.

## Solución de Problemas Comunes

### Error de Base de Datos
Si la aplicación se reinicia constantemente, verifica los logs. Si ves errores de conexión a la base de datos:
- Asegúrate de que `aplicar_postgres` es el nombre correcto del host interno (verifícalo en la pestaña de tu servicio Postgres).
- Verifica que la contraseña sea correcta en `DATABASE_URL`.

### Error "Table does not exist"
La aplicación debería ejecutar las migraciones automáticamente al iniciar. Si no lo hace:
1.  Ve a la consola de la aplicación en EasyPanel.
2.  Ejecuta manualmente: `node scripts/migrate.js run` (o el comando equivalente según tus scripts).

### Error 502 Bad Gateway
- Verifica que el puerto en la pestaña **Domains** esté configurado en `9000`.
- Asegúrate de que la aplicación esté escuchando en `0.0.0.0` y no solo en `localhost` (nuestra configuración ya maneja esto).
