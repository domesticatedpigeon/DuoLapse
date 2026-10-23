# Releasing DuoLapse

Releases are built, signed and published by `.github/workflows/release.yml` when a version tag is pushed. DuoLapse isn’t notarised, so it’s signed with a long-lived self-signed certificate instead of an Apple Developer ID.

## One-time setup

Do these once, on a Mac.

### 1. Create the signing identity

```sh
scripts/create-signing-identity.sh
```

This creates `~/DuoLapse Signing` with a 10-year certificate named “DuoLapse Self-Signed”. Add two repository secrets on GitHub (**Settings › Secrets and variables › Actions › Secrets**):

| Secret | Value |
| --- | --- |
| `SIGNING_CERTIFICATE_P12_BASE64` | contents of `DuoLapse-signing.p12.base64` |
| `SIGNING_CERTIFICATE_PASSWORD` | contents of `DuoLapse-signing.password` |

Back up the folder somewhere private. macOS ties Screen Recording and Camera permission to this certificate, so every release must use it. If it’s lost, users have to grant both permissions again after the next update.

### 2. Sign local builds with the same identity

macOS ties Screen Recording and Camera permission to the app's signature. Xcode's default ad-hoc signature changes on every build, so each rebuild asks for both permissions again. Import the identity into your login keychain once:

```sh
security import "$HOME/DuoLapse Signing/DuoLapse-signing.p12" \
  -k "$HOME/Library/Keychains/login.keychain-db" \
  -P "$(cat "$HOME/DuoLapse Signing/DuoLapse-signing.password")" \
  -T /usr/bin/codesign
```

Then build, sign and install with:

```sh
scripts/install-local.sh
```

Grant the permissions once more after the first signed install; later rebuilds and releases keep them.

### 3. Create the Sparkle update keys

Sparkle checks that each update was published by you, using its own EdDSA key pair.

1. Download the latest `Sparkle-2.x.tar.xz` from [Sparkle’s releases](https://github.com/sparkle-project/Sparkle/releases) and unpack it.
2. Run `./bin/generate_keys`. It stores the private key in your login keychain and prints the public key.
3. Run `./bin/generate_keys -x sparkle-private-key` to export the private key to a file.
4. On GitHub, add:
   - secret `SPARKLE_PRIVATE_KEY`: contents of `sparkle-private-key`
   - variable `SPARKLE_PUBLIC_ED_KEY` (**Settings › Secrets and variables › Actions › Variables**): the public key from step 2
5. Delete `sparkle-private-key`. The key stays in your keychain.

Builds without `SPARKLE_PUBLIC_ED_KEY`, such as local Xcode builds, run normally with “Check for Updates…” turned off.

## Publishing a release

1. Merge the release changes into `main`.
2. Tag the merge commit and push the tag:

   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. The workflow:
   - builds the Release configuration with the tag’s version and the run number as the build number
   - signs Sparkle’s helpers and the app with the self-signed identity and the hardened runtime
   - zips the app, signs the zip for Sparkle and writes `appcast.xml`
   - publishes both to a GitHub release with generated notes

Installed copies find the update through `releases/latest/download/appcast.xml`. The Homebrew cask in `Casks/duolapse.rb` always points at the latest release, so it needs no change per release.

## Checking a release

On a Mac that has never run DuoLapse:

1. Install from the release zip and follow the README’s first-launch steps.
2. Grant Screen Recording and Camera access, record a short timelapse, and export it.
3. Publish a later version, install it with **Check for Updates…**, and confirm DuoLapse still has both permissions.
4. Install with Homebrew from a clean tap and confirm the same first-launch steps work.
