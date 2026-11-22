# DARB Flutter app

Arabic RTL Flutter source. Requires Flutter and Android SDK. Run `flutter create --platforms=android .`, then `flutter pub get`.

Configure API host using `--dart-define=API_BASE_URL=https://YOUR_API_HOST/api/v1`.

Implemented mobile flows: OTP sign-in, customer store/catalog browsing, session cart and cash-on-delivery order placement, customer order list, seller order state actions and product creation, driver online toggle, order claiming and delivery state actions.

Not yet implemented: seller/driver application screens, address book management outside checkout, product edit/delete, admin console, push notifications, maps/live tracking, token auto-refresh, and production-grade persistent cart. This source has not yet passed `flutter analyze` or an Android release build.
