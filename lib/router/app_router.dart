import 'package:flutter/material.dart';

import 'package:sefim/ekran/proje_okuma_ekrani.dart';

abstract final class AppRouter {
  static const homeRoute = '/';
  static const irsaliyeRoute = '/irsaliye-ocr';
  static const projeOkumaRoute = '/proje-okuma';

  static Map<String, WidgetBuilder> routes({
    required Widget home,
    required Widget irsaliyeOcr,
    required void Function(BuildContext context) onAuthenticated,
  }) {
    return {
      homeRoute: (_) => home,
      irsaliyeRoute: (_) => irsaliyeOcr,
      projeOkumaRoute: (_) => const ProjeOkumaEkrani(),
    };
  }

  static void goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(homeRoute, (_) => false);
  }

  static Future<T?> push<T>(BuildContext context, String route) {
    return Navigator.of(context).pushNamed<T>(route);
  }
}
