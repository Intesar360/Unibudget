# UniBudget — Flutter frontend (CSE 464, Phase 2)

A student expense tracker: solid middle ground, not bare minimum
and not over the top. Full CRUD at the core, plus the screens that
make it look like real effort in a demo — without adding backend work.

## What it does

| Screen | What you can do |
|---|---|
| Login / Sign up | Email + password (with show/hide), name on Sign up; gates the app, Logout in Settings returns here |
| Home | Balance, total income/expense, spending by category, recent transactions |
| Add / Edit | Create and Update a transaction (one form for both) |
| History | Read, search, filter by type and by category; tap a row to Edit or Delete |
| Insights | Income vs expense by month, where the money goes, saved amount, biggest expense |
| Settings | Light / Dark / System theme (actually works), app info, data summary, Log out |

What it deliberately does NOT do: budgets, goals, notifications,
or recurring transactions. Each of those would be another backend
table or feature to build and demo.

Login is honest about Phase 2: it is a frontend demo gate, not
real authentication — any valid email and a 6+ character password
signs you in, and the name (or email prefix) becomes the Home
greeting. Phase 3 replaces only that check with a Django login
endpoint; the rest of the app never needs to know how auth
happened.

The trick that keeps it easy: Insights, the category filter,
Settings and the Login gate are all frontend-only. Insights is
computed from the transactions you already have, Settings is
local, and filters just narrow the same list. So the backend
stays exactly one table and one endpoint set (see below), while
the app still looks complete.

## How to run

```bash
cd unibudget_frontend
flutter pub get
flutter run
```

No backend needed for Phase 2: the app runs on demo data in
`lib/data/mock_data.dart`, through `MockTransactionRepository`.

## What I thought of your mockups

**Keep:** the overall look. Clean, spacious, readable, consistent
bottom nav (Home / + / History), navy + mint palette, rounded cards,
and the ৳ amounts. The Add screen's big amount and Income/Expense
toggle are good, and the History expanded card (payment method +
Edit / Delete) is exactly the right CRUD pattern — I kept it, on every
row, not just one.

**Fix before you demo — the numbers don't add up:**
- FreshMart is ৳350 on Home but ৳300 in History; Bus fare is ৳15 on
  Home but ৳18 in History.
- Salary is typed as the name on Add, but Allowance is the selected
  category. And on Home, Salary is labelled with the Study category.
- History's month totals (Oct ৳30.50, Sep ৳486.70, Aug ৳444.75)
  match none of the rows underneath them, and the header
  "All transactions ৳5,275.00" matches neither the Home balance
  (৳900) nor any sum of the rows.
- "On track" on Home means nothing — there is no budget target
  anywhere to be on track against. I dropped the badge instead of
  inventing a budget feature you said you don't want.

**How this code fixes it:** no screen ever types a total by hand.
`TransactionStore` computes balance, income, expense, category
totals and month nets from one list. Change a transaction and
every screen updates, because they all read the same store.
The demo data is chosen so the Home balance is still ৳900 —
income ৳7,500, expense ৳6,600 — but now that number is actually true.

**Other changes from the mockups:**
- Add screen: dropped the custom on-screen keypad. It took half the
  screen and duplicated the phone keyboard. The phone's numeric
  keyboard + a large amount preview does the same job.
- Add screen: category chips now switch with Income / Expense, and
  switching type resets the category — so the Salary/Allowance
  mismatch can't happen again.
- History: added search. Kept the All / Income / Expenses chips.
- Bottom nav: the + is a floating button over Home/History, not a
  third tab, so Back from Add returns to where you were.
- Dark theme included (follows the system) — light for the viva
  demo, dark for your own use.

## Structure

```
lib/
  main.dart                    # one-line swap for the real backend (Phase 3)
  models/transaction.dart      # Transaction + Category, fromJson/toJson
  data/mock_data.dart          # demo data only
  repositories/
    transaction_repository.dart # TransactionStore + Mock repository
  services/api_service.dart    # Phase 3 stub + backend contract
  theme/app_theme.dart         # navy + mint, light + dark
  utils/formatting.dart        # ৳ formatting, dates
  widgets/transaction_tile.dart # one row, used on Home + History
  screens/
    main_shell.dart            # Home / History / (+) / Insights / Settings
    login_screen.dart          # Login / Sign up gate (demo auth, Phase 2)
    home_screen.dart
    add_transaction_screen.dart # add AND edit — one form, not two
    history_screen.dart        # search + type + category filters
    insights_screen.dart       # computed only, no new data
    settings_screen.dart       # local theme + info + Log out
```

## Phase 3 backend — one table, that's it

Django + SQLite (Django's default). One model, one serializer,
one viewset, one URL:

```python
# models.py
class Transaction(models.Model):
    title = models.CharField(max_length=100)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_type = models.CharField(
        max_length=7, choices=[("income", "Income"), ("expense", "Expense")])
    category = models.CharField(max_length=20)  # food, transport, bills,
                                                # study, salary, allowance,
                                                # gift, refund, other
    date = models.DateField()
    payment_method = models.CharField(max_length=50, blank=True, null=True)

    class Meta:
        ordering = ["-date"]
```

Endpoints (see `services/api_service.dart` for the full contract):
`GET /api/transactions/`, `POST /api/transactions/`,
`PUT /api/transactions/<id>/`, `DELETE /api/transactions/<id>/`.

Then in `main.dart`, replace
`TransactionStore(MockTransactionRepository())` with
`TransactionStore(ApiTransactionRepository())` and add `http` to
`pubspec.yaml`. No screen changes. On an Android emulator, Django
on your PC is `http://10.0.2.2:8000`, not `127.0.0.1:8000`.

## Demo script for the viva (30 seconds)

1. Home shows ৳900.00 (7,500 income − 6,600 expense).
2. Tap + , add Lunch ৳250 as a Food expense — Home balance and
   Food total move, History gains a row.
3. In History, tap that row, Edit it to ৳300 — totals move again.
4. Delete it — everything returns to ৳900. That's full CRUD,
   with the numbers provably consistent at every step.
5. Open Insights — the month bars and category shares move with
   the edit/delete you just did. That shows the app is one
   connected system, not separate hardcoded screens.
```

