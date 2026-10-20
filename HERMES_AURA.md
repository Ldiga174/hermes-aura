# Hermes Aura (Android)

Public Android client fork of [rusty4444/hermes-android](https://github.com/rusty4444/hermes-android) for a self-hosted Nous Research Hermes Agent. Independently developed; not an official Nous Research app.

**Project state:** early public source fork. Not an audited or approved production APK. GitHub Actions are deliberately disabled during the initial review.

## Boundaries

- **Public:** app UI, protocol adapters, synthetic tests, security reports and generic instructions.
- **Private:** your Hermes host, chats, memory, profiles, wallet information, tokens, VPN settings, signing material and backups.
- The mobile application accesses Hermes through a private authenticated endpoint, preferably TLS inside a VPN. It does not clone the server's configuration.
- Never push sensitive runtime files to GitHub. Do not send private data to demo servers or public models.

## Roadmap

- [x] Fork source and preserve upstream attribution.
- [x] Initial static inspection and public security baseline.
- [x] Establish no-secrets policy and public project identity.
- [ ] Resolve licensing uncertainty before distributing our binaries.
- [ ] Enforce secure transport for release builds, with explicit safe test configuration.
- [ ] Add Aura visual identity and separate Android application ID.
- [ ] Review dependencies and tests; build isolated unsigned test artifacts.
- [ ] Test with a disposable gateway, then ship independently signed APKs.

See [security baseline](docs/HERMES_AURA_SECURITY.md) for findings, limitations and release requirements.

Upstream copyrights and third-party licenses remain with their respective owners. The MIT label in the upstream README is not treated as a verified license grant until clarified.
