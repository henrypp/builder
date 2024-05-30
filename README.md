## builder

### Short description of what doing this scripts:

- Build project portable zip package.
- Build project installation package.
- Update localization `.lng` file from `.ini` files ([as example](https://github.com/henrypp/builder#how-to-update-localization)).

### System requirements:

- Python 3.7+
- 7-Zip 21+ (used from `%path%`)
- GPG 2.2+ (used from `%path%`)
- NSIS 3+ (used from `%path%`)

### How to update localization:

- Sync this repository via:<br />
`git clone https://github.com/henrypp/builder.git`.
- Sync one of my project via:<br />
`git clone https://github.com/henrypp/simplewall.git`.
- Open cloned directory `simplewall\bin\i18n`.
- Open any available `.ini` file or copy `!example.txt` into new localization filename (eg. `Russian.ini`).
- Save modified file.
- Run `simplewall\build_locale.bat`
- The script was update `simplewall\bin\simplewall.lng` localization file.

- Website: [github.com/henrypp](https://github.com/henrypp)
- Support: sforce5@mail.ru
<br />
(c) 2018-2024 Henry++
