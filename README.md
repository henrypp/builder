## builder

### Short description of what doing this scripts:
- Build project portable zip package
- Build project installation package
- Update localization (.lng) file from .ini files ([as example](https://github.com/henrypp/builder#how-to-update-localization))

### System requirements:
- Python 3.x
- 7-Zip (used from `%path%`)
- NSIS (used from `%path%`)
- GPG (used from `%path%`)

### How to update localization:
- Sync one of my project `git@github.com:henrypp/simplewall.git`
- Open and edit any .ini file in `simplewall\bin\i18n`
- Save .ini file
- Sync builder `git@github.com:henrypp/builder.git`
- Run `simplewall\build_locale.bat`
- This script was update `simplewall\bin\simplewall.lng` locale file, you can put updated .lng file into simplewall.exe folder.

Website: [www.henrypp.org](https://www.henrypp.org)<br />
Support: support@henrypp.org<br />
<br />
(c) 2018-2022 Henry++
