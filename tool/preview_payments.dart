import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:flutter/material.dart';

/// 충전·거래 내역·QR 결제 미리보기.
/// flutter run -t tool/preview_payments.dart
void main() => runApp(const BazaarApp(initialLocation: Routes.my));
