<div align="center">

<img src="TBox/Assets.xcassets/AppIcon.appiconset/icon.png" width="120" alt="T-Box" />

# T-Box

**Cliente no oficial de [TorBox](https://torbox.app) para iPhone.**
Nativo, rápido y en español (e inglés). Pensado para instalar por sideload.

[![Última versión](https://img.shields.io/github/v/release/maniac75/t-box-for-torbox?label=versi%C3%B3n)](https://github.com/maniac75/t-box-for-torbox/releases/latest)
[![Build](https://github.com/maniac75/t-box-for-torbox/actions/workflows/build.yml/badge.svg)](https://github.com/maniac75/t-box-for-torbox/actions/workflows/build.yml)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-black?logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-nativo-orange?logo=swift)

**[⬇️ Descargar T-Box.ipa](https://github.com/maniac75/t-box-for-torbox/releases/latest/download/T-Box.ipa)** · [Novedades](CHANGELOG.md) · [Sitios compatibles](docs/SITIOS.md)

</div>

> T-Box no está afiliado a TorBox. "TorBox" es marca de sus respectivos dueños.
> *Unofficial TorBox client for iPhone, in Spanish and English. Not affiliated with TorBox.*

---

## ¿Qué es?

TorBox es un servicio en la nube que descarga torrents, archivos de sitios como Mega o Mediafire y videos de YouTube, Instagram o X, y te los entrega por un enlace rápido. Su web funciona en el iPhone, pero es incómoda. **T-Box** es una app nativa que habla directo con la API de TorBox: sin servidores intermedios, sin publicidad y sin rastreo.

## Funciones

### Agregar
- **Un solo lugar para todo**: pega magnets y enlaces web mezclados, uno por línea. Cada uno se reconoce solo y va a Torrents o a Web.
- **Archivos `.torrent`**, varios a la vez, desde Archivos o desde "Compartir".
- **Resultado en vivo** de cada enlace (agregado, en caché, en cola o error con su motivo) y su progreso en TorBox hasta que está listo.
- Tocar un **magnet en Safari** abre T-Box directamente.
- Opción **"solo si ya está en caché"** para no gastar cupos en descargas desde cero.
- Detección de **sitios compatibles** al pegar un enlace, con aviso si el sitio está caído. Corrige solo algunos enlaces problemáticos (Scribd).

### Biblioteca
- **Torrents** y **descargas web** con estado, progreso, velocidad y tiempo restante. Se refresca sola mientras hay algo en curso.
- **Barra de actividad** flotante con lo que está bajando en TorBox y al iPhone.
- Buscar, filtrar (todos, en curso, listos), eliminar y buscar más peers.

### Archivos
- **Reproducir** MP4/MOV con Picture in Picture y AirPlay. **Abrir en Infuse o VLC** para MKV y otros formatos.
- **Ver** PDF, imágenes, documentos y audio sin descargarlos a tu biblioteca.
- **Descargar al iPhone** en segundo plano, aunque cierres la app, a la **carpeta que elijas**: iCloud Drive, En mi iPhone o un disco.
- **Guardar fotos y videos directo en Fotos**, por ejemplo de Instagram o X.
- **Descargar todo como .zip** y **descomprimir** automáticamente o a pedido.
- Copiar o compartir el enlace temporal (no expone tu API key).

### Compartir
- **T-Box en el menú Compartir** de cualquier app: envía magnets y enlaces a TorBox sin salir de donde estás. [Detalles](#compartir-desde-otras-apps)

### Avisos
- Aviso dentro de la app cuando algo termina.
- **Notificaciones** cuando termina una descarga al iPhone o algo queda listo en TorBox.
- Botón **Probar notificación** en Cuenta.
- Opcional: **avisos instantáneos con [ntfy](https://ntfy.sh)** (experimental), configurados con un toque.

## Qué funciona en cada plan de TorBox

| | Free | Essential / Standard | Pro |
|---|:-:|:-:|:-:|
| Torrents, biblioteca, descargas al iPhone, reproducir y ver | ✅ | ✅ | ✅ |
| Descargas web (YouTube, Instagram, Mega…) | — | ✅ | ✅ |
| Usenet, streaming de TorBox, RSS *(próximamente en T-Box)* | — | — | ✅ |

¿No tienes cuenta? **[Créala con el código de referido del autor](https://torbox.app/subscription?referral=7b4a584a-00a5-430e-aa31-809aa4934cb0)**. Según TorBox, al comprar un plan pagado ambos reciben 7 días extra por cada mes comprado.

## Instalar

1. Descarga **[T-Box.ipa](https://github.com/maniac75/t-box-for-torbox/releases/latest/download/T-Box.ipa)** desde el iPhone.
2. Fírmala e instálala con tu método de sideload:
   - **Con certificado propio**: Feather, ESign, KSign u otra app de firma.
   - **Con Apple ID gratuito**: SideStore o AltStore. La firma vence cada 7 días y se renueva sola.
3. Abre T-Box y toca **Obtener código de acceso**: lo apruebas en torbox.app y la app recibe tu API key sola. También puedes pegar la key a mano.

Las versiones nuevas aparecen en [Releases](https://github.com/maniac75/t-box-for-torbox/releases) con su lista de cambios. Cada una trae `T-Box-X.Y.Z.ipa` (con la versión en el nombre) y `T-Box.ipa` (el mismo archivo con nombre fijo, para el botón de descarga directa).

## Compartir desde otras apps

Desde la versión 0.2.1, **T-Box aparece en el menú Compartir** de Safari, Instagram, YouTube, X, Scribd y cualquier app que comparta enlaces. Lo que pasa al tocarlo depende de cómo firmaste la app:

| Tu caso | Qué hace "T-Box" en Compartir |
|---|---|
| Tu firma permite compartir el llavero entre la app y su extensión (lo habitual con certificados de sideload) | **Envía a TorBox ahí mismo**, sin salir de la app donde estás, y muestra el resultado |
| Tu firma no lo permite | **Abre T-Box** con el enlace ya pegado: un toque más |
| T-Box no aparece en Compartir | Tu app de firma quitó la extensión: revisa que **"Eliminar extensiones / Remove PlugIns"** esté desactivado y vuelve a firmar. O usa el Atajo de abajo |

- La primera vez, T-Box puede no estar entre los íconos principales: desliza la fila hasta **Más** y actívalo.
- Para que envíe directo, abre T-Box una vez con tu sesión iniciada después de instalar.
- Con SideStore/AltStore y Apple ID gratuito, la extensión ocupa un identificador más de los 10 semanales que permite Apple.

### Alternativa: Atajo

Si la extensión no te funciona, un Atajo de iOS hace lo mismo:

1. Atajos › nuevo atajo › activa **Mostrar en hoja de compartir** y que reciba **URL** y **Texto**.
2. Acción **Codificar URL** sobre la entrada del atajo.
3. Acción **Abrir URL**: `tbox://add?text=` seguido del resultado codificado.

## Privacidad

- La API key se guarda en el **llavero del iPhone** y solo se envía a `api.torbox.app`.
- Sin analítica, sin anuncios, sin servidores propios.
- Los enlaces que compartes con otras apps son temporales y no contienen tu key.
- El diagnóstico exportable (Cuenta › Exportar diagnóstico) **censura la API key** automáticamente.

## Preguntas frecuentes

**¿Por qué no se reproduce un MKV dentro de la app?**
El reproductor de iOS no abre MKV. Usa **Abrir en Infuse** o **Abrir en VLC**. Un reproductor propio para MKV está en la hoja de ruta.

**Las notificaciones de TorBox llegan tarde con la app cerrada.**
iOS decide cuándo dejar que una app revise en segundo plano: a veces cada 15 minutos, a veces cada varias horas. Para avisos inmediatos activa **ntfy** en Cuenta.

**Volví a firmar la app y me pide iniciar sesión de nuevo.**
Es normal si cambiaste de certificado: el llavero queda asociado a quien firmó la app.

**¿Puedo usarla con otra cuenta o compilar mi propia versión?**
Sí. El código de referido y los enlaces están en [`TBox/Config.swift`](TBox/Config.swift).

## Hoja de ruta

- [ ] Biblioteca unificada (Torrents, Web, Usenet, cola), orden, filtros, títulos limpios y selección múltiple
- [ ] Etiqueta "iphone" con descarga automática, control de descargas (Wi-Fi, límite, pausa) y subida a la nube
- [ ] Ver: catálogo con fuentes de AIOStreams/Torrentio, reproductor MKV y streaming de TorBox (Pro)
- [ ] Estado de TorBox, estadísticas de la cuenta y RSS (Pro)

## Compilar

Cada cambio en `main` se compila y prueba en GitHub Actions. Al cambiar la versión (`MARKETING_VERSION` en `project.yml`), se publica una versión nueva con su sección de [CHANGELOG.md](CHANGELOG.md) como notas.

En un Mac:

```
brew install xcodegen
xcodegen generate
open TBox.xcodeproj
```

La lista de [sitios compatibles](docs/SITIOS.md) se actualiza sola cada semana desde la API de TorBox.
