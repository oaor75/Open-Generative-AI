# Notas de seguridad de este fork

Auditoría realizada el 2026-07-14 sobre `upstream/main` (commit `d4fb7ee`). Esta rama (`mejoras-seguridad`) corrige los hallazgos accionables. Los cambios son candidatos a PR hacia upstream.

## Corregido en esta rama

| ID | Severidad | Hallazgo | Fix |
|---|---|---|---|
| A1 | Alta | La API key se escribía en una cookie JS (`muapi_key`) sin `HttpOnly`/`Secure`, enviada en cada request durante 1 año. El backend ya la ignoraba: solo ampliaba la superficie de robo. | `components/StandaloneShell.js` — eliminada la escritura; se purga la cookie legada al montar. |
| A2 | Alta | `shell.openExternal(url)` sin validar esquema (un enlace `file:`/`smb:` podía lanzar ejecutables locales) y sin bloqueo de navegación del frame principal. | `electron/main.js` — allowlist `https/http/mailto` + handler `will-navigate`. |
| C1* | Crítica | Binarios de inferencia descargados, extraídos y ejecutados sin verificación de integridad. | `electron/lib/localInference.js` — verificación SHA-256: hash fijado para el binario propio (`CUSTOM_BINARY_SHA256`) y `digest` del asset de la API de GitHub para releases de leejet. Mismatch = descarga eliminada + error. |
| M1 | Media | CSP con `unsafe-eval` también en producción. | `middleware.js` — `unsafe-eval` solo en `NODE_ENV=development`. |
| M2 | Media | Copia huérfana de la clave en `localStorage["token"]` (DesignAgentStudio) que sobrevivía al cambio de clave. | `components/StandaloneShell.js` — se limpia en `handleKeyChange`. |
| M3 | Media | Nombre del asset remoto interpolado en `powershell -Command` (inyección) y usado sin sanear como ruta. | `electron/lib/localInference.js` — rutas vía variables de entorno, nombre saneado a `[A-Za-z0-9._-]`. |
| M4 | Media | `sandbox` no explícito en `webPreferences`. | `electron/main.js` — `sandbox: true` (el preload solo usa `contextBridge`/`ipcRenderer`, compatible). |
| B1 | Baja | El rewrite del middleware reenviaba cookies del navegador a `api.muapi.ai`. | `middleware.js` — se elimina la cabecera `cookie` antes del rewrite. |
| B5 | Baja | El contenedor Docker corría como root. | `Dockerfile` — `USER node` + `--chown` en la etapa runner. |

\* C1 queda **mitigado, no cerrado**: el `digest` de la API de GitHub protege el canal de descarga (CDN/MITM/corrupción), pero no un compromiso del propio release upstream. Cierre completo requeriría firmas (minisign/cosign) publicadas por upstream.

## Pendiente / riesgo aceptado

- **Submódulos sin auditar** (`packages/Vibe-Workflow`, `packages/Open-Poe-AI`, `packages/Open-AI-Design-Agent`): `npm run setup` compila código de repos de terceros. Auditar por separado antes de usar Workflow/Agents/Design; anclar cada submódulo a un commit revisado.
- **B2**: los proxies `/api/*` no tienen rate-limit ni restricción de origen. Irrelevante en uso local; añadir si se despliega públicamente.
- **B3/B4**: `console.log` de datos de negocio en proxies de workflow y S3 — limpiar en producción.
- **CSP `unsafe-inline`**: eliminarlo requiere infraestructura de nonces de Next.js; de valor menor mientras la clave viva en `localStorage`.
- **B6**: los instaladores distribuidos no van firmados con certificado real (proyecto OSS sin presupuesto de firma). Compilar desde código fuente si esto preocupa.

## Reglas para mantener este fork

1. La clave de MuAPI vive **solo** en `localStorage` (`muapi_key`) y viaja **solo** en la cabecera `x-api-key` hacia `api.muapi.ai`. Nunca en cookies, logs ni otros dominios.
2. Si cambias `CUSTOM_BINARIES`, actualiza `CUSTOM_BINARY_SHA256` en el mismo commit.
3. Instala dependencias con `npm ci` (respeta `package-lock.json`), no `npm install`.
4. Tras cada sync con upstream, revisa el diff de: `electron/main.js`, `electron/lib/localInference.js`, `middleware.js`, `components/StandaloneShell.js`, `app/api/**`.
