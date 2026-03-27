# 🚀 DPM Deployment Guide

This project is configured with a fully automated CI/CD pipeline using **GitHub Actions**.

## 🛡 Security (OIDC Publishing)
We use OpenID Connect (OIDC) to publish to **pub.dev**. This is the most secure method because it does not require storing a persistent secret token in your repository.

### One-Time Setup on Pub.dev
To enable the automated publisher:
1.  Navigate to your package page on [pub.dev](https://pub.dev/packages/dart_package_manager).
2.  Select **Admin** from the side menu.
3.  Click on **Automated Publishing**.
4.  Enable the **GitHub Actions** toggle.
5.  In the **Repository** field, enter: `bhuvancom/dart_package_manager`.
6.  (Required) Set the **Permissions** to include `id-token: write` and `contents: write` (already handled in our workflow).

---

## 🔐 Individual Developer (No Verified Publisher)
If you don't have a verified domain (like `bhuvan.dev`), you must use a **Repository Secret** instead of OIDC:

1.  **Get Credentials**: On your local machine, run `dart pub login`. After logging in, find your `pub-credentials.json`:
    - **macOS/Linux**: `~/.config/dart/pub-credentials.json`
    - **Windows**: `%APPDATA%\dart\pub-credentials.json`
2.  **Copy Content**: Open that file and copy the entire JSON content.
3.  **Add Secret**: On GitHub, go to **Settings** > **Secrets and variables** > **Actions**.
4.  **Name**: `PUB_DEV_PUBLISH_TOKEN`.
5.  **Value**: Paste the entire JSON content you copied.

DPM will now automatically detect this secret and use it for publishing!

---

## 🛡️ Branch Protection (Anti-Merge Guard)
To strictly prevent merging failing code to `master`:
1.  On GitHub: **Settings** > **Branches** > **Add branch protection rule**.
2.  Branch pattern: `master`.
3.  Enable **"Require status checks to pass before merging"**.
4.  In the search box, find and select: `build` (the name of our CI job).
5.  Enable **"Require branches to be up to date before merging"**.

This ensures that the "Merge" button is **disabled** if any test, build, or publish-check fails.

---

## 🏗 Workflow Details

### 1. Test & Verify (`test.yml`)
- Triggered on: Every Pull Request and Push to `master`.
- Actions: Runs `dart format`, `dart analyze`, `fvm dart test`, **`dart compile exe` (binary check)**, and **`dart pub publish --dry-run` (registry check)**.

### 2. Automated Release (`publish.yml`)
- Triggered on: Every Push to `master`.
- **Smart Logic**:
    - Detects the version from `pubspec.yaml`.
    - Checks if a Git tag (e.g., `v0.3.0`) already exists.
    - If the version is **NEW**:
        - Publishes the package to `pub.dev` via OIDC.
        - Automatically creates a new **Git Tag**.
        - Generates a **GitHub Release** with automated notes.

---

## 📦 Manual Releases
If you ever need to publish manually, you can still use:
```bash
dart pub publish
```
However, using the automated pipeline (by simply bumping the version in `pubspec.yaml` and pushing to `master`) is highly recommended to keep your tags and releases in sync!
