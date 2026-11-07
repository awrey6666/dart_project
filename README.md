# Ուսում

Приложение только для Windows. На компьютере нужен Flutter:
https://docs.flutter.dev/get-started/install

Первый запуск скачивает пакеты, поэтому нужен интернет.

Запуск: дважды щёлкните `run.bat`. Откроется окно программы.

Visual Studio не нужна. `run.bat` сам собирает окно.

## Admin panel (editing learning materials)

The admin panel opens **only** when the login page receives the built-in admin credentials:

| Field    | Value               |
| -------- | ------------------- |
| Username | `Admin_Panel_Access` |
| Password | `Admin_Panel_123`    |

(Both are case-sensitive.) Logging in with them opens the **«Ադմինի վահանակ»** directly.
Every other account, including the first one registered, is an ordinary student account with
no access to the panel. The username `Admin_Panel_Access` is reserved and can't be registered.
The admin session is never remembered, so the credentials are required on every launch.

To change the credentials edit `adminUsername` / `adminPassword` at the top of
`lib/learn/learn_controller.dart`. They are compiled into the app, so treat them as a
convenience gate for a local app, not as protection against someone who can read the binary.

In the panel you can:

- add / edit / delete **subjects** (name, group, colour) and **topics** (title, explanation),
- reorder topics (they unlock top to bottom),
- add / edit / delete **questions** of every type (choice, true/false, fill-in, numeric,
  ordering, matching, code, open),
- create student accounts and close student login (**Users** icon in the panel),
- restore the built-in content (menu in the panel),
- log out (door icon).

Edits are stored in `learn.content.json` next to the account files
(`%LOCALAPPDATA%\Usoum` on Windows). Until the first edit the app uses the built-in
catalog from `lib/learn/learn_catalog.dart` and `lib/learn/question_bank.dart`;
after the first edit the JSON file is the source of truth.

### Closing student login

The **«Սովորողների մուտքը փակ է»** switch on the Users page blocks student login and
self-registration (only the admin credentials work then). It is off by default. On an
existing install the saved value is kept, so if it was on before, turn it off there to let
students log in again.
