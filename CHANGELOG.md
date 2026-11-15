# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).
Each release ships `T-Box-X.Y.Z.ipa` and `T-Box.ipa` in [Releases](https://github.com/maniac75/t-box-for-torbox/releases). Versions before 0.3.0 are marked as pre-releases (early development).

*Registro de cambios en inglés. La app está en español e inglés.*

## [0.3.0] - 2026-11-15

### Added
- **Support T-Box** section in Account: Ko-fi, GitHub Sponsors and the TorBox referral code. A small card suggests it only once, after your 10th completed download, and never again.
- **Feedback** section in Account: report a bug (with app version, iOS and device prefilled), suggest an improvement, or join the discussions on GitHub.
- ♥ Sponsor button, issue forms (bug report and feature request) and Discussions on the GitHub repository.

### Changed
- Downloads are saved to **Files › On My iPhone › T-Box**, which is now visible. "Choose folder…" was removed because the iOS folder picker didn't respond. To move a file elsewhere: swipe › Save to… (Share sheet › Save to Files).
- Brief network drops during automatic refresh are no longer shown as errors, only if they happen three times in a row.
- The repository is now in English, with a Spanish README.

### Fixed
- **Share extension can send directly to TorBox** on certificates that sign with a wildcard keychain group (`TEAMID.*`, common with sideloading): the key is now stored in the group iOS actually assigns to the app, instead of a custom one that iOS rejected (error -34018).

## [0.2.3] - 2026-11-15

### Fixed
- **Choose download folder**: tapping "Open" did nothing. Switched to the native UIKit folder picker. *(Didn't solve it; replaced in 0.3.0.)*

## [0.2.2] - 2026-11-15

### Added
- **Activity**: swipe to delete stalled items from TorBox, **Delete stalled** button (no seeds or no progress) and **Cancel all** downloads to iPhone, including stuck ones.
- **Clear** the "Recently finished" list.

## [0.2.1] - 2026-11-15

### Added
- **T-Box in the Share sheet** of any app (Share extension). If the signing allows a shared keychain, it sends links to TorBox right there; otherwise it opens T-Box with the link filled in. It doesn't rely on App Groups, so it can't break installation with any certificate.
- **Test notification** button in Account › Notifications.
- **Show 18+ sites** toggle in the supported sites list.

### Changed
- The iOS Shortcut also accepts text (`tbox://add?text=`), to share magnets.

## [0.2.0] - 2026-11-15

### Added
- **Single add sheet**: one **+** on every tab. Paste magnets and web links mixed together (one per line); each is recognized and sent to Torrents or Web. Also accepts several `.torrent` files at once.
- **Live result** under the box: sending, added, cached, queued or error with its reason; then the progress in TorBox and, when done, **Download** and **To Photos** buttons right there.
- Floating **activity bar** with what's in progress in TorBox and downloading to the iPhone, with a detail panel.
- **In-app alerts** and **notifications** in the background (downloads to iPhone and items ready in TorBox).
- **Background check** of TorBox (iOS decides how often).
- **Download folder of your choice**, **Save to…** and **unzip .zip** automatically or on demand.
- **Preview** PDFs, images, documents and audio.
- **Instant alerts with ntfy** (experimental): sets TorBox's webhook to a private ntfy topic.

### Changed
- The **Add** button is now large, at the bottom, and rises with the keyboard.
- Links that are added are cleared from the box; failed ones stay so you can fix them. ✕ button to clear.
- `.torrent` files use TorBox's asynchronous endpoint (avoids 502 errors with large files).

### Fixed
- Internal **Scribd** links (`…?doc=ID`) are converted to the format TorBox accepts.
- The password field no longer offers saved passwords from other sites.
- Magnet names with `+` are shown with spaces.

## [0.1.1] - 2026-11-15

### Fixed
- The intermittent **"Operation cancelled"** message in Torrents and Web: refreshes were cancelling each other. Now only one refresh runs at a time and cancellations aren't shown as errors.

## [0.1.0] - 2026-11-15

### Added
- First version: sign in with a TorBox code or API key, torrent and web download lists with progress, add magnets and `.torrent` files, play MP4/MOV, open in Infuse or VLC, background downloads to Files, save to Photos, copy and share links.
- Supported site detection when pasting web links.
- Spanish and English, exportable diagnostics with the API key redacted, optional referral link.

[0.3.0]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.3.0
[0.2.3]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.3
[0.2.2]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.2
[0.2.1]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.1
[0.2.0]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.2.0
[0.1.1]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.1.1
[0.1.0]: https://github.com/maniac75/t-box-for-torbox/releases/tag/v0.1.0
