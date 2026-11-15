# Cambios

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versiones: [SemVer](https://semver.org/lang/es/).
Cada versión publicada trae su `T-Box.ipa` en [Releases](https://github.com/maniac75/t-box-for-torbox/releases).

## [0.2.3] - 2026-11-15

### Corregido
- **Elegir carpeta para descargas**: al tocar "Abrir" no pasaba nada. Ahora usa el selector de carpetas nativo de iOS y avisa si no puede guardar el acceso.

## [0.2.2] - 2026-11-15

### Agregado
- **Actividad**: desliza para eliminar de TorBox lo que no avanza, botón **Eliminar detenidos** (sin seeds o sin progreso) y **Cancelar todas** las descargas al iPhone, incluidas las que quedaron colgadas.
- **Limpiar** la lista "Terminado hace poco".

## [0.2.1] - 2026-11-15

### Agregado
- **T-Box en el menú Compartir** de cualquier app (extensión de Compartir). Si la firma permite compartir el llavero, envía los enlaces a TorBox ahí mismo; si no, abre T-Box con el enlace pegado. No depende de App Groups, así que no rompe la instalación con ningún certificado.
- Botón **Probar notificación** en Cuenta › Avisos.
- Interruptor **Mostrar sitios +18** en la lista de sitios compatibles.

### Cambiado
- El Atajo de iOS acepta también texto (`tbox://add?text=`), para compartir magnets.

## [0.2.0] - 2026-11-15

### Agregado
- **Hoja única para agregar**: un solo **+** en cualquier pestaña. Pegas magnets y enlaces web mezclados (uno por línea) y cada uno se reconoce solo y va a Torrents o a Web. También acepta varios archivos `.torrent` a la vez.
- **Resultado en vivo** debajo del cuadro: enviando, agregado, en caché, en cola o error con su motivo; luego el progreso en TorBox y, al terminar, botones **Descargar** y **A Fotos** ahí mismo.
- **Barra de actividad** flotante con lo que está en curso en TorBox y bajando al iPhone, y panel de detalle al tocarla.
- **Avisos al terminar** dentro de la app y **notificaciones** con la app en segundo plano (descargas al iPhone y cosas listas en TorBox).
- **Revisión en segundo plano** de TorBox (iOS decide la frecuencia).
- **Carpeta de descargas a elección** (iCloud Drive, En mi iPhone, discos), **Guardar en…** y **descomprimir .zip** automáticamente o a pedido.
- **Ver**: vista previa de PDF, imágenes, documentos y audio.
- **Avisos instantáneos con ntfy** (experimental): configura el webhook de TorBox hacia un tema privado de ntfy.

### Cambiado
- El botón **Agregar** ahora es grande, está abajo y sube con el teclado.
- Los enlaces que entran bien se borran del cuadro; los que fallan quedan para corregirlos. Botón ✕ para limpiar.
- Los `.torrent` se envían por el endpoint asíncrono de TorBox (evita errores 502 con archivos grandes).

### Corregido
- Los enlaces internos de **Scribd** (`…?doc=ID`) se convierten al formato que acepta TorBox.
- El campo de contraseña ya no ofrece contraseñas guardadas de otros sitios.
- Los nombres de magnets con `+` se muestran con espacios.

## [0.1.1] - 2026-11-15

### Corregido
- El aviso intermitente **"Operación cancelada"** en Torrents y Web: había refrescos que se cancelaban entre sí. Ahora hay un solo refresco a la vez y las cancelaciones no se muestran como error.

## [0.1.0] - 2026-11-15

### Agregado
- Primera versión: login con código de TorBox o API key, lista de torrents y descargas web con progreso, agregar magnets y `.torrent`, reproducir MP4/MOV, abrir en Infuse o VLC, descargas en segundo plano a Archivos, guardar en Fotos, copiar y compartir enlaces.
- Detección de sitios compatibles al pegar enlaces web.
- Español e inglés, diagnóstico exportable con la API key censurada, enlace de referido opcional.

[0.2.3]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.3
[0.2.2]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.2
[0.2.1]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.1
[0.2.0]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.0
[0.1.1]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.1.1
[0.1.0]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.1.0
