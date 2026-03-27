# 📦 Dart Package Manager (DPM)

**DPM** is a stunning, feature-rich, and interactive CLI built to modernize dependency management for Dart and Flutter. It goes beyond simple updates, providing a full suite of tools for optimization, security, and monorepo management.

---

## 🚀 Key Features

- **AI-Powered Discovery**: (`suggest`) Can't find the right package? Describe your requirement in natural language and let AI find it for you.
- **Interactive Updates**: Beautiful, multi-select terminal UI to selectively upgrade outdated packages.
- **Vulnerability Scanning**: Instant security audit using the [OSV API](https://osv.dev/).
- **Unused Dependency Detection**: (`analyze`) Scan your codebase to find packages taking up space but never imported.
- **Deep Clean ("Nuke It")**: (`clean`) Aggressively wipe `.dart_tool`, `build`, and lockfiles to fix stubborn environment issues.
- **Interactive Search & Install**: (`add`) Search pub.dev directly from the terminal with metrics like Likes and Description.
- **Monorepo Support**: (`-r`) Recursive command execution across nested `pubspec.yaml` files.
- **Inline Changelogs**: View changelog links before confirming updates.

---

## 🛠 AI Features

To unlock **AI Discovery**, get a free API key from [Google AI Studio](https://aistudio.google.com/) and either:

1. **Set Environment Variable**:
   ```bash
   export DPM_API_KEY="your-api-key"
   ```
2. **Use CLI Flag**:
   ```bash
   dpm suggest "your requirement" --api-key="your-api-key"
   ```
3. **Choose Model** (Optional):
   ```bash
   dpm suggest "your requirement" --model="gemini-1.5-pro"
   ```

---

## 🛠 Installation

Activate globally with Dart:

```bash
dart pub global activate dart_package_manager
```

> [!TIP]
> If `dpm` is not found after activation, your `pub-cache/bin` might not be in your PATH. You can run it using:
> ```bash
> dart pub global run dart_package_manager:dpm <command>
> ```

---

## 📖 Usage

DPM uses a subcommand-based architecture. Simply run `dpm` to see all options.

### Commands

| Command | Description |
|---|---|
| `dpm update` | Interactively check and update dependencies (Default). |
| `dpm add <query>` | Search and install a package from pub.dev. |
| `dpm suggest <req>` | Ask AI to find packages based on requirements. |
| `dpm analyze` | Scan for unused dependencies. Use `--ignore` to skip packages. |
| `dpm clean` | Deep clean caches, lockfiles, and strictly reinstall. |

### Global Flags

- `-h, --help`: Show usage information.
- `-v, --verbose`: Enable detailed logging.
- `-r, --recursive`: Run a command recursively on all sub-projects in the workspace.

### Examples

**Search and add a state management library:**
```bash
dpm add provider
```

**Discover a package using AI:**
```bash
dpm suggest "I need to pick images from gallery and crop them"
```

**Analyze and clean a large monorepo:**
```bash
dpm analyze -r
dpm clean -r
```

**Check for updates with verbose logging:**
```bash
dpm update --verbose
```

For automated testing and publishing setup, see our [Deployment Guide](DEPLOYMENT.md).

---

## 🏗 Architecture

DPM is built using **SOLID Principles** and **Clean Architecture**:
- **Domain Layer**: Pure business logic (Use Cases).
- **Data Layer**: Repository implementations for FileSystem, System, and Pub.dev APIs.
- **Presentation Layer**: Interactive CLI commands and formatted UI.

---

## 🤝 Contributing

Feel free to open issues or submit PRs to make DPM the best tool for the community!

