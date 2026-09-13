# Baloto App (bl_app)

App móvil para consultar resultados, histórico y verificar jugadas de Baloto y Revancha (Colombia), construida con Flutter.

## Funcionalidades

- **Resultados** — último sorteo de Baloto y Revancha con superbalota.
- **Pull-to-refresh** — en Inicio e Histórico el gesto de arrastre hacia
  abajo recarga los datos (mismo camino seguro que el botón «Recargar» del
  AppBar), incluso cuando el contenido es más corto que la pantalla.
- **Caché offline** — el último resultado y el histórico se persisten en
  `shared_preferences`; si la petición falla por conexión, la app muestra
  el último dato guardado con un aviso «Datos sin conexión» en vez de una
  pantalla de error (ver [Caché offline](#caché-offline)).
- **Fechas legibles** — las fechas ISO del backend (`2026-09-05`) se muestran
  en formato español («5 sept 2026») vía `intl` (ver `lib/utils/fechas.dart`).
- **Histórico** — sorteos anteriores con pestañas por juego (lista completa;
  el backend ya no pagina) y búsqueda local por número de sorteo.
- **Verificar números** — 6 campos (5 números + Superbalota destacada) con validación, auto-avance y cálculo de premios.
- **Generador aleatorio** — combinaciones válidas con animación de mezcla y copia al portapapeles.
- **Más resultados** — enlace al histórico completo del sitio oficial
  (`baloto.com/resultados`) vía `url_launcher`, desde Inicio y el AppBar de Histórico.
- **Splash institucional** — logo + crédito «© 2026 Gaelectronica» + versión
  al arrancar, con fundido hacia la app.

## Arquitectura

```
lib/
├── config/
│   ├── apiConfig.dart        # URL base y timeout de la API (único lugar)
│   └── appTheme.dart         # Tema oscuro premium + paleta de colores
├── models/
│   └── sorteo.dart           # Modelos tipados con fromJson
├── services/
│   ├── balotoApi.dart        # Todas las llamadas HTTP + manejo de errores
│   ├── cachedContentStore.dart # Caché offline (shared_preferences)
│   ├── generadorNumeros.dart # Lógica de combinaciones (Random inyectable)
│   └── ...
├── utils/
│   └── fechas.dart           # formatearFecha: ISO → «5 sept 2026» (intl)
├── widgets/
│   ├── balota.dart           # Widget reutilizable de balota con animación
│   ├── balotoSiteLink.dart   # Enlace a baloto.com/resultados (url_launcher)
│   ├── errorRetryView.dart   # Estado de error compartido (ícono + Reintentar)
│   └── loadingView.dart      # Estado de carga compartido (spinner + mensaje)
└── screens/
    ├── splashScreen.dart     # Splash in-app: logo + © + versión
    ├── homeScreen.dart       # Último resultado + CTA verificar + enlace web
    ├── historicoScreen.dart  # Histórico con pestañas y búsqueda local
    ├── verificarScreen.dart  # Verificación de jugadas
    └── generadorScreen.dart  # Generador aleatorio
```

Las pantallas solo manejan UI: nunca importan `package:http` ni `dart:convert`.
El flujo es `Screen → Service → http`, con modelos tipados (`Sorteo`, `Historico`,
`Verificacion`) para autocompletado y errores en tiempo de compilación.

### Tema visual

La app usa un tema oscuro premium definido en `lib/config/appTheme.dart`:

| Color | Hex | Uso |
|-------|-----|-----|
| Background | `#070B1A` | Fondo principal |
| Surface | `#0D1430` | Superficies elevadas |
| Baloto | `#4F7CFF` | Acento azul (_BALOTO_) |
| Revancha | `#FF8A3D` | Acento naranja (_REVANCHA_) |
| Superbalota | `#FFC93C` | Acento ámbar |
| Superbalota (texto/foco) | `#FF5722` / `#EF6C00` | Campo SB de Verificar |
| On Accent | `#FFFFFF` | Contenido sobre botones de acento |
| Splash background | `#FFFFFF` | Fondo del splash in-app |

Todos los colores de las pantallas salen de `AppColors` (no hay
`Colors.amber`/`Colors.white` sueltos en `lib/screens`).

### Estados de carga y error

`LoadingView` y `ErrorRetryView` (`lib/widgets/`) son los estados
compartidos de Inicio e Histórico: cada `FutureBuilder` queda como
`LoadingView` → `ErrorRetryView` → contenido, con la misma apariencia y
el mismo botón «Reintentar» en ambas pantallas.

### Splash Screen

Configurado con `flutter_native_splash`. Muestra sobre fondo **blanco**
(`#FFFFFF`) la imagen compuesta `assets/splash_full.png`: logo + crédito
«© 2026 Gaelectronica» + versión **horneados en la imagen**, para que el
texto institucional sea visible desde el primer segundo (en dispositivos
lentos el arranque en frío puede tardar varios segundos antes del primer
frame de Flutter; el splash nativo es lo único en pantalla durante ese
periodo). El glifo del logo es azul marino y desaparece sobre fondos
oscuros, por eso el fondo es blanco.

```bash
dart run flutter_native_splash:create   # regenerar tras cambios en pubspec.yaml
powershell -File tool/upscale_splash.ps1  # SIEMPRE después: amplía mdpi/hdpi
```

> Importante: `flutter_native_splash` genera mdpi=fuente/4 (256px); en
> tablets mdpi de 600px esa imagen se dibuja 1:1 y el branding se ve
> minúsculo. `tool/upscale_splash.ps1` amplía mdpi→512 y hdpi→640 tras
> cada regeneración. Para editar el diseño del splash nativo, modificar
> `tool/compose_splash.ps1` y ejecutar ambos scripts.

Además, al entrar la app muestra un **splash in-app**
(`lib/screens/splashScreen.dart`) con el logo animado y el mismo crédito;
tras ~2 s entra al shell con un fundido. En pruebas se salta con
`MyApp(api: ..., mostrarSplash: false)`.

> En Android el renderer Impeller está desactivado en el manifest:
> en GPUs MediaTek antiguas (Android 9) se queda en pantalla blanca
> sin pintar frames.

### API

El backend consume `bl-gae-api.onrender.com` (ver `lib/config/apiConfig.dart`);
el contrato completo vive en `openapi.json`:

| Endpoint | Uso |
| --- | --- |
| `GET /baloto/ultimo` | Último sorteo (Baloto + Revancha) |
| `GET /baloto/historico` | Histórico completo (sin paginación) |
| `GET /baloto/verificar?numeros=1,2,3,4,5&superbalota=6` | Verificación contra el último sorteo |

Notas del contrato actual:

- El backend **eliminó la paginación** del histórico: la respuesta ya no
  incluye el bloque `paginacion` ni acepta `page`/`limit`.
- El endpoint `/baloto/verificar-por-fecha` fue **retirado**: la verificación
  es siempre contra el último sorteo.
- `premio` en la verificación es un **identificador de categoría** (1–7,
  0 = sin premio), no un monto monetario.

Los errores del backend llegan como `ApiException` con mensaje listo para UI.

### Caché offline

El backend vive en el tier gratuito de Render (con cold starts), así que la
app persiste el último dato bueno en `shared_preferences`
(`lib/services/cachedContentStore.dart`):

- Cada respuesta **exitosa** de `/baloto/ultimo` y `/baloto/historico` se
  guarda como JSON (claves `cache_baloto_ultimo_v1` y
  `cache_baloto_historico_v1`).
- Si la petición **falla** (timeout, sin conexión, 5xx sin cuerpo), la API
  devuelve el dato cacheado: el usuario ve datos al instante en vez de un
  error. Un `ApiException` solo llega a la UI si **no hay caché**.
- El origen del dato viaja en `ResultadoEnLinea<T>` (`origen: red | cache`);
  cuando viene del caché, las pantallas muestran un aviso discreto
  «Datos sin conexión» (`lib/widgets/cachedDataBanner.dart`) para que el
  usuario sepa que lo que ve puede no ser lo más reciente.
- Si el JSON cacheado está corrupto se trata como caché vacío (todo el
  store es no-throw).
- Al cambiar el formato guardado, subir el sufijo `_v1` de las claves
  invalida el caché viejo de todos los usuarios.

La verificación (`/baloto/verificar`) no se cachea: depende de los números
que ingresa el usuario y siempre refleja el último sorteo en servidor.

## Tests

76+ pruebas (unitarias y de widgets), todas sin red real:

```bash
flutter test          # toda la suite
flutter analyze       # análisis estático
```

- **Servicios** — `BalotoApi` con `MockClient` (parseo, errores, timeout),
  `GeneradorNumeros` con semillas fijas (determinismo, rangos, unicidad).
- **Pantallas** — cada pantalla recibe un `BalotoApi` opcional para inyectar
  mocks: carga, éxito, error, navegación, validaciones y tarjetas de resultado.
- **Enlace web** — `abrirSitioBaloto` es una variable sobreescribible para
  simular `url_launcher` sin plataforma (éxito, rechazo y excepción).
- **Widgets compartidos** — `ErrorRetryView`, `LoadingView` (mensaje
  opcional, callback de reintento) y `CachedDataBanner` (aviso de datos
  offline).
- **Fechas** — `formatearFecha`: formato español, timestamps ISO completos,
  y strings no parseables que se devuelven intactos.
- **Caché offline** — round-trip de modelos vía `toJson`/`fromJson`, JSON
  corrupto tratado como caché vacío, store no-throw sin prefs, y el
  fallback de `BalotoApi` (sirve caché al fallar, relanza si no hay,
  persiste respuestas exitosas) con `SharedPreferences.setMockInitialValues`.

## Ícono de la app

Los íconos se generaron desde `images/` (ahora eliminada; el set completo de
Apple queda documentado en el historial de Git):

- **Android** — `mipmap-*` en las 5 densidades + ícono adaptativo
  (`mipmap-anydpi-v26/`) con fondo blanco configurable en
  `res/values/ic_launcher_background.xml` e ícono monochrome para Android 13+.
- **iOS** — `AppIcon.appiconset` en formato moderno Xcode 14+
  (un solo PNG de 1024×1024).

## Plataformas

Proyecto multiplataforma (Android, iOS, web, Windows, macOS, Linux).

| Plataforma | Splash screen | Notas |
|------------|---------------|-------|
| Android | Nativo | Incluye soporte Android 12+ (API 31+) |
| iOS | Nativo | LaunchScreen.storyboard con imagen centrada |
| Web | CSS + imágenes | Light/dark mode, resolución 1x→4x |
| macOS | No configurado | Requiere soporte manual |
| Windows | No configurado | Requiere soporte manual |

Para correr en Android:

```bash
flutter pub get
flutter run -d <device-id>   # ej: flutter run -d HA11V6D8
```

La primera compilación de Android descarga el SDK/NDK y dependencias de Gradle
(varios minutos; requiere conexión estable a `repo.maven.apache.org`).

### Requisitos en Windows

- **Modo desarrollador activado**: al existir un plugin nativo
  (`url_launcher`), `flutter pub get` y los builds necesitan soporte de
  symlinks (`start ms-settings:developers`).
- **Caracteres raros en debug (©, acentos)**: es un bug conocido de Flutter
  en Windows, solo afecta al modo debug; en release se ven correctos.
  Verificar siempre con `flutter build windows --release` y ejecutar
  `build\windows\x64\runner\Release\bl_app.exe`.
- **`kotlin.incremental=false`** en `android/gradle.properties`: el daemon de
  Kotlin de este equipo falla al cerrar sus cachés incrementales
  ("Could not close incremental caches"). Si se actualiza Gradle/Kotlin se
  puede probar a reactivarla.
- `url_launcher` en Android 11+ requiere el `<intent>` con
  `android.intent.action.VIEW` en el `<queries>` del manifest (ya incluido).

## Build de release

### Android

```bash
# APK normal (firma de debug)
flutter build apk --release

# APK con ofuscación (recomendado para producción)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# AAB (Android App Bundle) para Google Play
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

La ofuscación renombra clases y métodos a nombres ilegibles, dificultando el
reverse engineering. El mapa de desobfusqueda se guarda en `build/debug-info/`
(guardarlo para leer stack traces en crash reports).

**Firma de release:** copiar `android/key.properties.example` a
`android/key.properties` y completar las credenciales de la keystore.
Si no existe keystore válida, se usa firma de debug automáticamente.
