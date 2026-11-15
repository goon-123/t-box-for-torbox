# T-Box

**Cliente no oficial para [TorBox](https://torbox.app) en iPhone.** Nativo (SwiftUI, iOS 17+), pensado para instalar por sideload.

> T-Box no está afiliado a TorBox. "TorBox" es marca de sus respectivos dueños.
> *Unofficial TorBox client for iPhone. Not affiliated with TorBox.*

## Qué hace hoy

- **Login con TorBox** (apruebas un código en torbox.app) o pegando tu API key. La key se guarda en el llavero.
- **Agregar todo desde un solo lugar**: pega magnets y enlaces web mezclados (uno por línea) o elige archivos `.torrent`. Cada línea se reconoce sola, muestra su resultado debajo y sigue su progreso en TorBox hasta que está lista. Tocar un magnet en Safari abre la app.
- **Torrents y descargas web** ([más de 160 sitios](https://api.torbox.app/v1/api/webdl/hosters): YouTube, Instagram, X, TikTok, Mega…) con estado, progreso y refresco automático.
- **Barra de actividad** con lo que está en curso en TorBox y bajando al iPhone, y aviso al terminar.
- **Notificaciones**: descargas al iPhone terminadas y cosas listas en TorBox (con la app cerrada, iOS decide cada cuánto revisar). Opcional: avisos instantáneos vía [ntfy](https://ntfy.sh) (experimental).
- **Por archivo**: reproducir (MP4/MOV), ver (PDF, imágenes, documentos), abrir en Infuse o VLC, descargar en segundo plano, guardar fotos y videos en Fotos, copiar o compartir el enlace.
- **Descargas**: carpeta por defecto a elección (iCloud Drive, En mi iPhone, discos), "Guardar en…", descomprimir `.zip` automáticamente o a pedido.
- **Español e inglés.** **Diagnóstico exportable** con la API key censurada.

## Instalar

1. Descarga `T-Box.ipa` desde [Releases](../../releases) o desde el último build en [Actions](../../actions).
2. Fírmalo con tu app de firma (Feather, ESign, KSign, SideStore…) y tu propio certificado.

¿No tienes cuenta de TorBox? [Créala con el código de referido del autor](https://torbox.app/subscription?referral=7b4a584a-00a5-430e-aa31-809aa4934cb0): según TorBox, ambos reciben 7 días extra por cada mes comprado.

## Mandar enlaces desde otras apps

Crea un Atajo con "Mostrar en hoja de compartir" (recibe URL) → **Codificar URL** → **Abrir URL** `tbox://add?url=` + resultado. Los magnets van a Torrents y el resto a Web.

## Compilar

Cada push a `main` compila y prueba en GitHub Actions. Las etiquetas `vX.Y.Z` publican un release con el `.ipa`.

En un Mac:

```
brew install xcodegen
xcodegen generate
open TBox.xcodeproj
```

Para tu propia versión, cambia el código de referido y los enlaces en `TBox/Config.swift`.

## Hoja de ruta

- Biblioteca unificada (Torrents, Web, Usenet, cola), orden, filtros, selección múltiple, caché local
- Cola de agregado con revisión de caché, control de descargas, etiqueta "iphone", subida a la nube
- Ver: catálogo con fuentes de AIOStreams/Torrentio, reproductor MKV, streaming de TorBox (Pro)
- Avisos de "listo", estado de TorBox, estadísticas, RSS (Pro)
