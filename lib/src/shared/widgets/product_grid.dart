import 'package:flutter/material.dart';

/// One responsive grid definition shared by every product grid (shop feed,
/// search, category, wishlist) and its loading skeleton, so column count and
/// card proportions never drift between them.
///
/// Max-extent sizing keeps 2 columns on phones (a ~210px tile cap yields 2
/// across every common phone width) and automatically adds columns on wider
/// screens — foldables and tablets — instead of stretching two giant cards.
/// The proven 0.62 ratio is retained so cards never overflow.
const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 210,
  mainAxisSpacing: 14,
  crossAxisSpacing: 14,
  childAspectRatio: 0.62,
);
