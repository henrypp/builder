## builder

### Short description of what doing this scripts:

- Build project portable `7z` package.
- Build project installation package.
- Update localization `.lng` file from `.ini` files ([as example](https://github.com/henrypp/builder#how-to-update-localization)).

### System requirements:

- Python 3.13+
- 7-Zip 24+ (used from `%path%`)
- GPG 2.5+ (used from `%path%`)
- NSIS 3.10+ (used from `%path%`)

### How to update localization:

- Sync this repository via:<br />
`git clone https://github.com/henrypp/builder.git`.
- Sync one of my project via:<br />
`git clone https://github.com/henrypp/simplewall.git`.
- Open cloned directory `simplewall\bin\i18n`.
- Open any available `.ini` file or copy `!example.txt` into new localization filename (eg. `Russian.ini`) and save modified file.
- Run `simplewall\build_locale.bat`
- The script will update `simplewall\bin\simplewall.lng` localization file.
---
- Website: [github.com/henrypp](https://github.com/henrypp)
- Support: sforce5@mail.ru
---
(c) 2018-2024 Henry++
