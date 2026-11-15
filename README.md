# UniBudget

A student expense tracker built with Flutter — track income and expenses in Bangladeshi Taka (৳), see where your money goes by category, and review your monthly spending at a glance.

This repository is the **frontend (Flutter app)**.

> **Backend:** [Mehedisohel/Unibudget_backend](https://github.com/Mehedisohel/Unibudget_backend) — Django REST API with JWT authentication  
> **Live API:** https://unibudget-backend-2.onrender.com

---

## Features

- **Login & Register** — real accounts via the Django backend (JWT)
- **Home** — total balance, income / expense summary, spending-by-category breakdown, and your 5 most recent transactions
- **Add / Edit Transactions** — title, amount, income or expense, date, category, and payment method (Cash, bKash, Debit card, Bank transfer)
- **History** — transactions grouped by month with monthly net, plus search and filters (All / Income / Expenses, by category)
- **Insights** — monthly income vs. expense, amount saved, biggest expense, and category totals
- **Settings** — edit display name, choose an avatar, switch theme (System / Light / Dark), and log out
- **Categories**
  - Income: Salary, Allowance, Gift, Refund
  - Expense: Food, Transport, Bills, Study, Other
- **Dark mode** — full light and dark themes based on the UniBudget navy / royal blue / teal brand colours

## Screens

Login → Main shell with 4 tabs — **Home**, **History**, **Insights**, **Settings** — and a centre **+** button to add a transaction.

## Tech Stack

| Part | Technology |
|---|---|
| Frontend (this repo) | Flutter / Dart (SDK `>=3.4.0 <4.0.0`), Material 3 |
| State | `ChangeNotifier` — `TransactionStore` is the single source of truth for all totals |
| Networking | `http` package |
| Backend | Django + Django REST Framework, Simple JWT — [see backend repo](https://github.com/Mehedisohel/Unibudget_backend) |
| Database (backend) | PostgreSQL |

## Backend

This app does not work standalone for real accounts — it talks to the UniBudget Django backend:

- **Repository:** https://github.com/Mehedisohel/Unibudget_backend
- **Live API:** https://unibudget-backend-2.onrender.com

### Connecting the app to the backend

The API base URL is set in one place — `lib/services/api_service.dart`:

```dart
const String apiBaseUrl = 'http://192.168.0.103:8000';
```

Change it to match how you are running the backend:

- **Live / deployed backend:** `https://unibudget-backend-2.onrender.com`
- **Real phone + local Django:** your PC's LAN IP, e.g. `http://192.168.0.103:8000` — run Django with `python manage.py runserver 0.0.0.0:8000` and add that IP to `ALLOWED_HOSTS` in the backend's `settings.py`
- **Android emulator + local Django:** `http://10.0.2.2:8000`

### API endpoints used by the app

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/register/` | Create account — returns `{access, refresh, user}` |
| POST | `/login/` | Log in — returns `{access, refresh, user}` |
| POST | `/refresh/` | Refresh the access token |
| GET | `/api/transactions/` | List transactions, newest first |
| POST | `/api/transactions/` | Create a transaction |
| PUT | `/api/transactions/<id>/` | Update a transaction |
| DELETE | `/api/transactions/<id>/` | Delete a transaction |

All transaction calls require `Authorization: Bearer <access token>`. Access tokens last 30 minutes; the app automatically tries one refresh (7-day refresh token) and retries once on a `401`.

The backend also provides `/me/`, `/change-password/`, `/logout/`, `/categories/`, `/summary/`, `/reports/monthly/`, and `/api/budgets/` — see the [backend repo](https://github.com/Mehedisohel/Unibudget_backend) for full details.

## Getting Started (Frontend)

For a full first-time setup on Windows — installing VS Code, the Flutter SDK, and Android Studio / Android SDK, and running the app on a real phone — see **[SETUP_WINDOWS.md](SETUP_WINDOWS.md)**.

Short version:

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
  main.dart                        # App entry — auth & theme state, Login → MainShell
  models/
    transaction.dart               # Transaction, TransactionType, Category
  repositories/
    transaction_repository.dart    # TransactionStore + repository interface
                                   # (Mock for Phase 2, API for Phase 3)
  services/
    api_service.dart               # Django API client, JWT handling
  data/
    mock_data.dart                 # Phase 2 demo data (empty — blank account)
  screens/
    login_screen.dart
    main_shell.dart                # Bottom navigation + centre + button
    home_screen.dart
    add_transaction_screen.dart
    history_screen.dart
    insights_screen.dart
    settings_screen.dart
  theme/
    app_theme.dart                 # Light + dark theme, brand colours
  widgets/
    transaction_tile.dart
    profile_avatar.dart
    animated_in.dart
  utils/
    formatting.dart                # ৳ money and date formatting
assets/
  unibudget_logo.png
```

**Design rule:** screens never calculate their own totals. Every number comes from `TransactionStore` (balance, income, expense, month totals), so Home, History, and Insights always agree. Screens also never talk to the API directly — swapping `MockTransactionRepository` for `ApiTransactionRepository` in `main.dart` was the only change needed to go from Phase 2 demo data to the Phase 3 backend.

## Related Repositories

- **Frontend (this repo):** https://github.com/Intesar360/Unibudget
- **Backend:** https://github.com/Mehedisohel/Unibudget_backend

## Contributors

- **Intesar Hossain** — Frontend (Flutter app)
- **Mohammad Mehedi Sohel** — Backend (Django REST API)
