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

Sign in with the seeded customer account:

| Email                | Password       |
|----------------------|----------------|
| customer@nhstyx.com  | `Customer@123` |

> Or tap **Register your store** to create a new boutique account.

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
    │   ├── auth/                    # login, register, session controller
    │   ├── products/               # catalog browse + search
    │   ├── cart/                    # local cart + quantity logic
    │   ├── orders/                  # checkout + order history
    │   └── home/                    # bottom-nav shell + profile
    └── shared/                      # formatters, reusable widgets
test/
└── cart_controller_test.dart       # cart logic unit tests
```

### State management (Riverpod)
- `authControllerProvider` — `AsyncNotifier<User?>`; restores the session on
  launch, exposes `login` / `register` / `logout`.
- `productsProvider` — `FutureProvider`, reactive to `productSearchProvider`.
- `cartControllerProvider` — `Notifier<List<CartItem>>` with derived
  `cartCountProvider` / `cartSubtotalProvider`.
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
