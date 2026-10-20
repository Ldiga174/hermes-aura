#!/usr/bin/env python3
"""Minimal source-only security regression checks for Hermes Aura.

This test has no credentials, makes no network requests, and cannot contact
a real Hermes gateway. It is not a full security audit.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise AssertionError(reason)


def main() -> None:
    gradle = read("android/app/build.gradle.kts")
    manifest = read("android/app/src/main/AndroidManifest.xml")
    config = read("android/app/src/main/res/xml/network_security_config.xml")
    updates = read("lib/core/services/app_update_service.dart")

    require('applicationId = "com.ldiga.hermesaura"' in gradle,
            "Aura must have a separate Android package ID")
    require('manifestPlaceholders["appLabel"] = "Hermes Aura"' in gradle,
            "Aura must have an independent Android name")
    require('android:usesCleartextTraffic="false"' in manifest,
            "The Android manifest must disallow plaintext connections")
    require('cleartextTrafficPermitted="false"' in config,
            "Network security config must reject plaintext connections")
    require('<certificates src="user"' not in config,
            "Release config must not trust arbitrary user certificate authorities")
    require('<certificates src="system"' in config,
            "Release TLS configuration must use system trust anchors")
    require('https://api.github.com/repos/Ldiga174/hermes-aura/releases/latest' in updates,
            "Aura updates must not point to upstream releases")
    require('getBool(checkOnLaunchKey) ?? false' in updates,
            "Automatic update checks must be opt-in")
    require('android:allowBackup="false"' in manifest,
            "Android system backup must be disabled for secret-bearing data")

    tracked_bytes = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    files = [entry.decode("utf-8", errors="replace")
             for entry in tracked_bytes.split(b"\x00") if entry]
    bad_names = [
        f for f in files
        if Path(f).name.lower() in {
            ".env", "key.properties", "release.keystore",
            "google-services.json", "credentials.json",
        } or Path(f).suffix.lower() in {".pem", ".p12", ".pfx", ".jks"}
    ]
    require(not bad_names, "Forbidden tracked secret-like filenames: " + str(bad_names))
    print("HERMES_AURA_SOURCE_SECURITY=PASS")
    print("Checks: separate app identity, TLS policy, update privacy, backup, tracked filenames")
    print("Not checked: runtime SSL behavior, Android permissions, dependencies, secrets in history")


if __name__ == "__main__":
    main()
