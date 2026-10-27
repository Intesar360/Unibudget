# UniBudget — first-time Flutter setup (Windows)

You do **not** need to learn all of Flutter first. Install the tools,
run this project, then learn by changing small things in it. That is
the fastest way for a first project.

## The idea in one paragraph

Flutter is Google's toolkit for building phone apps. You write the
app once, in a language called Dart, and Flutter turns it into a
real Android app. The files in `lib/` are the app. `lib/main.dart`
is where it starts. A "widget" is just a building block on screen —
a button, a card, a text field. You mostly arrange widgets.

## Step 1 — Install VS Code (the editor)

1. Download VS Code from code.visualstudio.com and install it.
2. Open VS Code, go to Extensions (left sidebar), install:
   - **Flutter** (this also installs Dart — you need both)
3. VS Code is lighter than full Android Studio, which matters on
   an older CPU. You will still install Android Studio in Step 3,
   but only for its Android SDK — you won't write code in it.

## Step 2 — Install the Flutter SDK

1. Go to docs.flutter.dev/get-started/install/windows.
2. Download the Flutter SDK zip. Extract it to **`C:\src\flutter`**
   — not to Program Files, not to a folder with spaces in its name.
   Short paths avoid a whole class of Windows errors.
3. Add it to PATH so any terminal can find the `flutter` command:
   - Windows search → "Edit the system environment variables"
     → Environment Variables → under your user variables, select
     **Path** → Edit → New → `C:\src\flutter\bin` → OK on everything.
   - Close and reopen any terminal / VS Code window afterwards,
     or the new PATH won't be picked up.
4. In a new terminal (PowerShell or VS Code's terminal), run:
   ```powershell
   flutter --version
   ```
   If it prints a version, Step 2 is done.

## Step 3 — Install Android Studio (for the Android SDK only)

1. Download Android Studio from developer.android.com/studio and
   install it with the default options.
2. Open it once, let it finish its first-time setup. This installs
   the Android SDK, which is what actually builds the Android app.
3. Back in your terminal, run:
   ```powershell
   flutter doctor --android-licenses
   ```
   Press `y` for every licence prompt. This is the step most
   beginners miss, and without it the build fails.
4. Then run:
   ```powershell
   flutter doctor
   ```
   You want ticks for Flutter, Android toolchain, and VS Code.
   A warning about Chrome or Visual Studio (for Windows apps) can
   be ignored — this project is Android-only. Fix anything that
   says `[!]` next to Android toolchain before moving on.

## Step 4 — Get this project onto your PC

1. Download the `unibudget_frontend.zip` that came with this guide
   and extract it somewhere short and simple, e.g.
   `C:\projects\unibudget_frontend`.
2. In VS Code: File → Open Folder → that folder.
3. Open a terminal inside VS Code (Terminal → New Terminal) and run:
   ```powershell
   flutter pub get
   ```
   This downloads the project's dependencies (there are almost
   none — just Flutter itself and icons). First time takes a minute.

## Step 5 — Run it on your phone (recommended)

An emulator is slow on an older CPU, so use your real phone:

1. On your Meizu: Settings → About phone → tap **Build number**
   7 times until it says you are a developer.
2. Go back to Settings → Developer options → turn on
   **USB debugging**.
3. Connect the phone to your PC with a USB cable. On the phone,
   tap **Allow** when it asks about USB debugging (tick
   "Always allow from this computer" if offered).
4. In the VS Code terminal, run:
   ```powershell
   flutter devices
   ```
   Your phone should be listed. If it says "unauthorized", unplug,
   plug back in, and allow again.
5. Run the app:
   ```powershell
   flutter run
   ```
   The first build takes a few minutes (it downloads Gradle and
   builds everything once). Later runs are much faster. The app
   should open on your phone on the Login page.

### If you'd rather use an emulator

In Android Studio: Device Manager → Create device → pick a Pixel
phone → download a system image → Finish, then press Play. Then
`flutter devices` should list the emulator, and `flutter run`
uses it. Expect it to be slower than your phone.

## Step 6 — Try it, then change something

1. On the Login page, enter any valid-looking email and any
   password of 6+ characters — e.g. `intesar@test.com` /
   `123456`. Phase 2 has no real accounts yet (see README), so
   any valid pair signs you in.
2. Add a transaction with the centre **+** button, edit it from
   History, delete it, and watch Home and Insights update.
   That is the whole CRUD demo.

Then learn by breaking things safely — the app rebuilds live:

| Try this | Where |
|---|---|
| Change the app name / greeting | `lib/screens/home_screen.dart` |
| Change the navy / mint colours | `lib/theme/app_theme.dart` |
| Add a demo transaction | `lib/data/mock_data.dart` |
| Change a screen's layout | `lib/screens/<that screen>.dart` |

After saving a file, the running app updates by itself. In the
terminal, `r` = hot reload (keeps your place), `R` = hot restart
(starts fresh), `q` = quit.

## The project, in plain language

```
lib/
  main.dart            # starts the app; Login first, then the tabs
  screens/             # one file per page you see
  models/              # what a Transaction is (title, amount, type…)
  repositories/        # TransactionStore: the one list every screen reads
  data/mock_data.dart  # demo transactions for Phase 2 (no backend yet)
  theme/app_theme.dart # colours, light + dark theme
  widgets/             # the transaction row, reused on Home + History
```

Rule that keeps the app sane: screens never invent a total. They
ask `TransactionStore` (balance, income, expense, month totals),
so Home, History and Insights always agree.

## Common first-time errors

| Error | Fix |
|---|---|
| `flutter` is not recognized | PATH step missed, or terminal opened before PATH was set. Close the terminal and reopen it. |
| Android licences not accepted | Run `flutter doctor --android-licenses` and accept all. |
| No devices found | USB debugging off, cable is charge-only, or debugging not allowed on the phone. Try another cable / USB port. |
| Device unauthorized | Unplug, reconnect, tap Allow on the phone. |
| First build takes very long | Normal. It downloads Gradle once. Don't cancel it. |
| `flutter doctor` complains about Chrome / Visual Studio | Ignore for this project — those are for web / Windows apps. |

## What you do NOT need yet

- **No Dart course first.** Learn Dart as you read this code:
  a class is a blueprint, a widget is a screen piece, `setState`
  means "redraw with the new value".
- **No Django yet.** That is Phase 3 (due Dec 13). For Phase 2
  (due Nov 1), the frontend on demo data is the deliverable.
- **No Play Store, no signing keys, no release build.** `flutter run`
  in debug mode is all a university demo needs.

## Disk-space note

Flutter + Android SDK need several GB free. If your drives are
tight, install to the drive with the most free space, and keep a
copy of this project folder on Google Drive as backup.
