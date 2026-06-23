# NH Styx — Customer App

The Flutter mobile app for **garment store & boutique owners** to browse the wholesale catalog, build a cart, and place orders — everything their store needs in one place.

**Stack:** Flutter · Riverpod (state) · go_router (navigation) · Dio (HTTP) · flutter_secure_storage (tokens).

---

## ⚠️ First-time setup

This repository contains the Dart source and project config. The platform
folders (`android/`, `ios/`, `web/`, etc.) are **not** committed — generate them
once with Flutter, which preserves `lib/`, `test/`, and `pubspec.yaml`:

```bash
flutter create .          # regenerates platform folders in place
flutter pub get
```

Then run against a locally-running backend:

```bash
# Android emulator (reaches host at 10.0.2.2 — the default):
flutter run

# iOS simulator / web / desktop (override the API URL):
flutter run --dart-define=API_BASE_URL=http://localhost:4000/api/v1
```

Sign in with the seeded customer account (**phone + password**):

| Phone        | Password       |
|--------------|----------------|
| `9876543210` | `Customer@123` |

> Or tap **Register your store** to create a new boutique account.
> Prices are shown in ₹ (the API uses integer paise); GST is computed at
> checkout from your delivery state. The cart lives server-side.

---

## Architecture

Feature-first, with a light data → domain → presentation split per feature:

```
lib/
├── main.dart                       # ProviderScope + app bootstrap
└── src/
    ├── app.dart                    # MaterialApp.router + theme
    ├── core/
    │   ├── config/app_config.dart  # API base URL (dart-define)
    │   ├── network/                # Dio client (+ auth/refresh), ApiException
    │   ├── router/app_router.dart  # go_router + auth redirect
    │   ├── storage/token_storage.dart  # secure token storage
    │   └── theme/app_theme.dart    # Material 3 theme
    ├── features/
    │   ├── auth/                    # phone login, register, session controller
    │   ├── products/               # catalog browse + search (paise, tiers)
    │   ├── cart/                    # server-side cart + checkout panel
    │   ├── addresses/              # delivery addresses (+ add screen)
    │   ├── orders/                  # GST checkout + order history
    │   └── home/                    # bottom-nav shell + profile
    └── shared/                      # formatters (paise→₹), reusable widgets
test/
├── domain_test.dart                # product/cart parsing + money formatting
└── widget_test.dart                # login screen smoke test
```

### State management (Riverpod)
- `authControllerProvider` — `AsyncNotifier<Customer?>`; restores the session on
  launch, exposes `login(phone, password)` / `register` / `logout`.
- `productsProvider` — `FutureProvider`, reactive to `productSearchProvider`.
- `cartControllerProvider` — `AsyncNotifier<Cart>` backed by the server cart,
  with a derived `cartCountProvider` for the nav badge.
- `addressesProvider` / `defaultAddressProvider` — delivery addresses.
- `checkoutControllerProvider` / `ordersProvider` — place orders & list history.

### Networking
`Dio` injects the bearer token on every request and performs a single
refresh-and-retry when the API returns `401`.

---

## Scripts

```bash
flutter pub get        # install dependencies
flutter analyze        # static analysis / lints
flutter test           # run unit tests
flutter run            # launch on a device/emulator
flutter build apk      # release Android build
```
