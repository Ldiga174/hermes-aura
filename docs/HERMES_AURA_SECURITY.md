# Hermes Aura — security baseline (2026-10-20)

Source reviewed: `rusty4444/hermes-android` at commit `67a1df1e541243b67c7ac77418b8bdc37a3ee6d3`.
This is an initial static source review, **not** a claim that the application or any APK is safe.

## Design boundary

- This is an Android client, not a second Hermes runtime. No Hermes host data is to be copied to GitHub.
- A public repository may contain source code, docs, synthetic fixtures and test data only.
- Never commit tokens, API keys, cookies, passwords, chat transcripts, private memories, real gateway URLs/IP addresses, SSH/VPN configurations, wallet details, keystores, signing keys or unredacted screenshots.
- Connection credentials belong solely in the runtime's secure device storage; server-side credentials stay on the Hermes server.
- Develop against disposable local test gateways using synthetic sessions. No production permissions for testing.
- Route remote connections via authenticated Tailscale or comparable private VPN, with TLS/HTTPS. Never expose an unauthenticated dashboard/API to the public Internet.

## Findings (preliminary)

**HIGH in upstream — cleartext and trust boundary**: the original Android manifest allowed cleartext traffic and the original network security config trusted user-installed CAs. Hermes Aura source has now changed to `usesCleartextTraffic=false`, `cleartextTrafficPermitted=false`, and system CAs only. This is a **source-level mitigation, not a verified runtime fix**; Android/Flutter networking and emulator tests remain mandatory before any real credentials.

**MEDIUM — configurable high-privilege endpoints**: the client can control sessions, scheduled tasks, approvals and settings on the connected Hermes host. Require least-privilege gateway credentials, server authorization and device lock. Do not use production connection until assessed.

**MEDIUM — configuration export contains credentials**: `config_backup.dart` includes API keys and passwords in the backup payload, but encrypts exported data using PBKDF2-HMAC-SHA256 and AES-256-GCM. Treat backups as secrets; never commit them. Review cryptography and import limits before production use.

**LOW/PRIVACY — external update check**: the original checked upstream GitHub Releases. Aura now uses its own release endpoint and defaults the automatic check to off. Manual checks may still contact GitHub; no releases exist yet.

**POSITIVE**: the connection manager uses `flutter_secure_storage` backed by Android Keystore; Android `allowBackup=false`; no hardcoded token/key patterns in tracked HEAD in a targeted string scan; no obvious Dart TLS bypass callback in the targeted search. These checks do not exclude vulnerabilities or malicious dependencies.

**LEGAL BLOCKER**: README labels the project MIT, while `NOTICE.md` explicitly states there was no upstream LICENSE file and does not assert a license grant. GitHub's fork feature preserves attribution, but permission to redistribute modified APKs is not established here. Verify rights with maintainers before public binary distribution.

**UNVERIFIED**: Flutter/Dart analyze and tests, full dependency and supply-chain audit, real Android network traces, signing/updates, security regression tests and penetration testing. Flutter/Dart tooling was not installed on the review Windows machine. **Do not claim this build is production-safe.**

## Release gates

1. Resolve upstream license and attribution (BLOCKER).
2. Validate HTTPS-only networking at runtime; audit authentication, backup, deep-links and file import.
3. Review pinned Flutter dependencies and GitHub workflow supply chain.
4. Run `flutter analyze`, `flutter test`, Android emulator/device tests.
5. Inspect signed APK manifest/network behavior and publish checksums from controlled CI.
6. Activate CI only after review, with a new Aura signing key and no operator credentials.

Report vulnerabilities privately to maintainers; do not post credentials or production identifiers in issues.
