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
- Service startup tweaks are merged into `init/Win10.psm1` and applied from `init/Default.preset`.