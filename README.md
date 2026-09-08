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
│   └── apiConfig.dart        # URL base y timeout de la API (único lugar)
├── models/
│   └── sorteo.dart           # Modelos tipados con fromJson
├── services/
│   ├── balotoApi.dart        # Todas las llamadas HTTP + manejo de errores
│   ├── generadorNumeros.dart # Lógica de combinaciones (Random inyectable)
│   └── ...
└── screens/
    ├── homeScreen.dart       # Último resultado
    ├── historicoScreen.dart  # Histórico con pestañas
    ├── verificarScreen.dart  # Verificación de jugadas
    └── generadorScreen.dart  # Generador aleatorio
```

Las pantallas solo manejan UI: nunca importan `package:http` ni `dart:convert`.
El flujo es `Screen → Service → http`, con modelos tipados (`Sorteo`, `Historico`,
`Verificacion`) para autocompletado y errores en tiempo de compilación.

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
Para correr en Android:

```bash
flutter pub get
flutter run -d <device-id>   # ej: flutter run -d HA11V6D8
```

La primera compilación de Android descarga el SDK/NDK y dependencias de Gradle
(varios minutos; requiere conexión estable a `repo.maven.apache.org`).
