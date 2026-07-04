import 'package:flutter/material.dart';
import 'app_localizations.dart';

extension TransCtx on BuildContext {
  String t(String key) => AppLocalizations.of(this).t(key);
}
