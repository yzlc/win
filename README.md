# win

Windows personal setup scripts and command tools.

## Layout

- `init/`: Win10 initial setup preset and upstream tweak library.
- `config/`: User-level configuration modules. Each runnable module owns a `run.bat`.
- `config/apps/`: application configuration files for Git, Maven, npm, pip, SVN, and IDEA.
- `config/tools/`: command tools installed into the Start menu and exposed by Scoop.
- `config/tools/commands/`: standalone commands such as v2rayN update/restart and Shutdown23 task creation.
- `config/tools/poe/`: POE launch helpers used by generated shortcuts.
- `config/tools/zju-connect/`: zju-connect launcher used by generated shortcuts.

## Usage

Run scripts from an elevated command prompt only after reviewing the target file.

- `config/config.bat` runs each module `run.bat` one by one and reports failures.
- `init/Default.cmd` applies `init/Default.preset`. It is intentionally guarded by a confirmation prompt because the preset changes system privacy, security, services, Windows apps, and UI settings.

## Notes

- Git TLS verification is kept enabled.
- Git credentials use Git Credential Manager instead of plain-text `credential.helper store`.
- Conda and pip mirror files are copied from `config/apps/pip/`.
- Scoop installs this repo into its own app directory; command tool shortcuts are generated from `config/tools/` and use that directory directly.
- POE and zju-connect helpers are also generated as Start menu shortcuts and pinned when Windows exposes the pin verb.
- Some scripts contain machine-specific paths such as `C:\Program Files\Epic Games\PathOfExile`; update them before using on another machine.
