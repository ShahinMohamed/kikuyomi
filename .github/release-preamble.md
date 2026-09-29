Kikuyomi is an audiobook player and ebook reader whose content comes from installable JavaScript
extensions. It is not in any app store and will not be: a store holds a developer answerable for
everything a plug-in does, and this app cannot make promises about extensions it does not write
(ADR-0010). Downloading it here is the intended way to get it.

## Which file

| Platform | File | How to install |
| --- | --- | --- |
| Android | `kikuyomi-<version>-android.apk` | Open the APK and allow installation from this source when asked |
| Windows | `kikuyomi-<version>-windows-x64.zip` | Unpack anywhere and run `kikuyomi.exe`; keep the DLLs and the `data` folder beside it |
| iOS | `kikuyomi-<version>-ios-unsigned.ipa` | Sideload with AltStore or SideStore, which re-signs it for you |

## What to expect

**Windows will warn you.** The executable is unsigned, so SmartScreen shows "Windows protected your
PC" until the build accumulates reputation. That is the honest cost of shipping outside a store, and
the source is here to read.

**The iOS build is unsigned on purpose.** A free Apple ID signs it for seven days at a time and
allows three sideloaded apps at once. Enterprise-certificate signing services are deliberately not
used: their shared certificates get revoked in waves, taking every app signed with them offline
together.

**An APK named `-debug-signed` is exactly that** — built without the release keystore, so Android
will not install it over a properly signed build and the two cannot be mixed. Uninstall before
switching between them.

## Reporting something broken

Open an issue with what you did, what happened, and the platform. If an extension misbehaved, go to
**More → Extension console**: it copies everything the extensions have logged in one tap, which is
worth far more than a description.

---
