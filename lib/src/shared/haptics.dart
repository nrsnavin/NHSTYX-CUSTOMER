import 'package:flutter/services.dart';

/// Small, consistent haptic vocabulary so physical feedback feels intentional
/// rather than ad-hoc. Kept in one place so the whole app speaks the same
/// "language" of touch.
class Haptics {
  const Haptics._();

  /// A discrete selection change — stepper +/−, toggles, chips.
  static void tap() => HapticFeedback.selectionClick();

  /// A confirming action succeeded — added to cart, coupon applied.
  static void success() => HapticFeedback.lightImpact();

  /// A weightier confirmation — order placed, payment done.
  static void heavy() => HapticFeedback.mediumImpact();

  /// Something was rejected or failed.
  static void error() => HapticFeedback.heavyImpact();
}
