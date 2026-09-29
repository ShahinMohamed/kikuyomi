# Releasing

How a build reaches somebody else. There is no app store in this project's future (ADR-0010), so a
GitHub Release is not one distribution channel among several — it is the only one, and the in-app
update checker reads what it publishes. That is why this document is longer than the two commands
at its centre deserve.

## Cutting a release

1. **Decide the version** and set it in `app/pubspec.yaml`. The line is `version: <name>+<code>`.
   The name is what people see; the code is what Android compares, so it **must** increase on every
   build that could be installed over another, and it never goes down.
2. **Update `app/lib/src/app_version.dart`** to match. A test fails if the two disagree, so this is
   not something you can forget — but it is something you can be surprised by, so change both
   together.
3. **Commit, tag and push the tag.**

   ```powershell
   git tag v1.0.0
   git push origin v1.0.0
   ```

   The tag is what starts the pipeline. Pushing the commit does not.
4. **Watch the run.** All three builds must finish before anything is published, so a failure
   leaves the tag with no release attached rather than a half-populated one. Fix, delete the tag,
   and tag again.

The tag decides whether GitHub marks the release a pre-release: `v1.0.0` is a full release, and
anything with a suffix — `v1.0.0-beta.1` — is a pre-release. That is the only signal a GitHub
Release has for "not the one to recommend yet", so use it rather than saying so in the notes alone.

## Trying it without spending a tag

A release that fails on the third platform after two succeeded is an annoying thing to discover from
a tag. Run the workflow by hand from the Actions tab (**Release → Run workflow**) and it builds all
three and publishes nothing. Do this after any change to the build files, the SDK version or the
signing setup.

## The Android keystore

The keystore is the identity of the app on Android. Whoever holds it and its passwords can publish
an update that Android will install over a real one, and — this is the part that surprises people —
**losing it cannot be undone**. There is no recovery, no reissue, and no way to publish an update to
anyone who installed a build signed with it. A new keystore means a new app that cannot upgrade the
old one.

So: create it once, and back it up in two places that are not the machine you made it on.

### Creating it

`keytool` comes with the JDK. From anywhere:

```powershell
keytool -genkey -v -keystore kikuyomi-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias kikuyomi
```

It asks for a keystore password, a key password and a name. Ten thousand days is about
twenty-seven years, which is the point: a certificate that expires is a certificate that strands
every installed copy.

### Putting it into CI

The keystore is a binary file and a GitHub secret holds text, so it goes in base64:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("kikuyomi-release.jks")) | Set-Clipboard
```

Then add four repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | What it holds |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the output of the command above |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | `kikuyomi`, unless you chose another alias |
| `ANDROID_KEY_PASSWORD` | the key password |

All four or none. The workflow fails deliberately if the keystore is present and a password is not,
rather than signing with keys nobody holds.

### Building signed on your own machine

Create `app/android/key.properties`, which is gitignored:

```properties
storeFile=C:/path/to/kikuyomi-release.jks
storePassword=...
keyAlias=kikuyomi
keyPassword=...
```

Without that file the release build signs with the debug keys, so `flutter run --release` and a
contributor's clone both still work. An APK built that way is named `-debug-signed` by CI, because
Android refuses to install it over a properly signed build and the difference must be visible
before somebody downloads it.

## What the version number cannot say

Every bundled extension and every entry in the official repository declares
`"minAppVersion": "1.0.0"`. An app version below that makes the compatibility check refuse **every
extension**, which on a first run looks like an app with no sources at all. So the version can rise
freely and cannot fall below 1.0.0 without re-signing the repository index to match.

This is worth knowing because it removes the obvious way to say "this is early". Use the tag suffix
and the release notes for that instead.
