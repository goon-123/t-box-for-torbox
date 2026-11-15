# T-Box

**Cliente no oficial para [TorBox](https://torbox.app) en iPhone.** Nativo (SwiftUI, iOS 17+), pensado para instalar por sideload.

> T-Box no está afiliado a TorBox. "TorBox" es marca de sus respectivos dueños.
> *Unofficial TorBox client for iPhone. Not affiliated with TorBox.*

## Qué hace hoy

- **Login con TorBox** (apruebas un código en torbox.app) o pegando tu API key. La key se guarda en el llavero.
- **Torrents**: estado, progreso, velocidad y tiempo restante, con refresco automático; agregar magnet (tocar un magnet en Safari abre la app) o `.torrent`; opción "solo si está en caché"; eliminar y buscar más peers.
- **Descargas web**: pega enlaces de YouTube, Instagram, X, TikTok, Mega, Mediafire y [más de 160 sitios](https://api.torbox.app/v1/api/webdl/hosters); la app detecta el sitio y avisa si está caído. Requiere plan pagado.
- **Por archivo**: reproducir (MP4/MOV), abrir en Infuse o VLC, descargar a Archivos en segundo plano, **guardar fotos y videos directo en Fotos**, copiar o compartir el enlace.
- **Español e inglés.**
- **Diagnóstico exportable** (Cuenta › Exportar diagnóstico), con la API key censurada.

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
