> ## ⚠️ Testing build. Expect it to break.
>
> This is early. There are bugs, features are missing, and some of it has never run outside CI.
>
> Android especially: nobody has run this on an actual phone yet. If you install the APK, you're the
> first. It might not even start.
>
> Turn backups on (Settings → Backup) and expect to reinstall at some point. Bug reports welcome.

Kikuyomi is an audiobook player and ebook reader. Where the books come from is up to you: you
install extensions for the sites you want.

It's not on Google Play or the App Store and won't be. Stores hold the developer responsible for
whatever a plugin does, and that's not a promise this app can make. So you download it here.

## Which file

| Platform | File | How to install |
| --- | --- | --- |
| Android | `kikuyomi-<version>-android.apk` | Open it and allow installs from this source |
| Windows | `kikuyomi-<version>-windows-x64.zip` | Unpack it and run `kikuyomi.exe`. Keep the DLLs and the `data` folder next to it |
| iOS | `kikuyomi-<version>-ios-unsigned.ipa` | Sideload with AltStore or SideStore |

## Things you'll run into

**Windows will flag it.** The exe isn't code-signed, so SmartScreen throws up "Windows protected
your PC". Click "More info" then "Run anyway", or don't. The source is right here if you'd rather
build it yourself.

**iOS builds are unsigned.** AltStore and SideStore re-sign them for you. On a free Apple ID that
lasts 7 days before it needs redoing, and you can only have 3 sideloaded apps at once. We don't use
enterprise certificates. Those get revoked in batches and take every app signed with them down at
once.

**If an APK is named `-debug-signed`**, it wasn't built with the real key. Android won't install it
over a properly signed build, so uninstall first if you're switching between them.

## Something broken?

Open an issue: what you did, what happened, which platform. If an extension was involved, go to
**More → Extension console** and hit copy. That log is far more useful than a description.

---
