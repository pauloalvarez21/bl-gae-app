# Baloto App (bl_app)

App móvil para consultar resultados, histórico y verificar jugadas de Baloto y Revancha (Colombia), construida con Flutter.

## Funcionalidades

- **Resultados** — último sorteo de Baloto y Revancha con superbalota.
- **Histórico** — sorteos anteriores con pestañas por juego.
- **Verificar números** — 6 campos (5 números + Superbalota destacada) con validación, auto-avance y cálculo de premios.
- **Generador aleatorio** — combinaciones válidas con animación de mezcla y copia al portapapeles.

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
│   ├── generadorNumeros.dart # Lógica de combinaciones (Random inyectable)
│   └── ...
├── widgets/
│   └── balota.dart           # Widget reutilizable de balota con animación
└── screens/
    ├── homeScreen.dart       # Último resultado + accesos rápidos
    ├── historicoScreen.dart  # Histórico con pestañas
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

### Splash Screen

Configurado con `flutter_native_splash`. Muestra el ícono de la app centrado
sobre fondo oscuro (`#070B1A`) en Android, iOS y Web.

```bash
dart run flutter_native_splash:create   # regenerar tras cambios en pubspec.yaml
```

### API

El backend consume `bl-gae-api.onrender.com` (ver `lib/config/apiConfig.dart`):

| Endpoint | Uso |
| --- | --- |
| `GET /baloto/ultimo` | Último sorteo (Baloto + Revancha) |
| `GET /baloto/historico` | Histórico completo |
| `GET /baloto/verificar?numeros=1,2,3,4,5&superbalota=6` | Verificación de jugada |

Los errores del backend llegan como `ApiException` con mensaje listo para UI.

## Tests

44+ pruebas (unitarias y de widgets), todas sin red real:

```bash
flutter test          # toda la suite
flutter analyze       # análisis estático
```

- **Servicios** — `BalotoApi` con `MockClient` (parseo, errores, timeout),
  `GeneradorNumeros` con semillas fijas (determinismo, rangos, unicidad).
- **Pantallas** — cada pantalla recibe un `BalotoApi` opcional para inyectar
  mocks: carga, éxito, error, navegación, validaciones y tarjetas de resultado.

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
