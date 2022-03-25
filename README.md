## builder

### Short description of what doing this scripts:

- Build project portable zip package.
- Build project installation package.
- Update localization (.lng) file from .ini files ([as example](https://github.com/henrypp/builder#how-to-update-localization)).

### System requirements:

- Python 3.x
- 7-Zip (used from `%path%`)
- NSIS (used from `%path%`)
- GPG (used from `%path%`)

### How to update localization:

- Sync this repository.
- Sync one of my project (eg. `git@github.com:henrypp/simplewall.git`).
- Open synced directory `simplewall\bin\i18n`.
- Copy `!example.txt` into new localization filename (eg. `German.ini`) or edit any available localization file.
- Save updated `.ini` file.
- Run `simplewall\build_locale.bat`
- This script was update `simplewall\bin\simplewall.lng` localization file.

Website: [www.henrypp.org](https://www.henrypp.org)<br />
Support: support@henrypp.org<br />
<br />
(c) 2018-2022 Henry++
