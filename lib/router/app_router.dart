import 'package:flutter/material.dart';

import 'package:sefim/ekran/auth_ekrani.dart';
import 'package:sefim/ekran/bildirimler_ekrani.dart';
import 'package:sefim/ekran/proje_okuma_ekrani.dart';
import 'package:sefim/ekran/santiye_secim_ekrani.dart';

abstract final class AppRouter {
  static const authRoute = '/auth';
  static const santiyeRoute = '/santiye-secim';
  static const bildirimlerRoute = '/bildirimler';
  static const homeRoute = '/';
  static const irsaliyeRoute = '/irsaliye-ocr';
  static const projeOkumaRoute = '/proje-okuma';

  static Map<String, WidgetBuilder> routes({
    required Widget home,
    required Widget irsaliyeOcr,
    required void Function(BuildContext context) onAuthenticated,
  }) {
    return {
      authRoute: (context) => AuthEkrani(onAuthenticated: onAuthenticated),
      santiyeRoute: (_) => const SantiyeSecimEkrani(),
      bildirimlerRoute: (_) => const BildirimlerEkrani(),
      homeRoute: (_) => home,
      irsaliyeRoute: (_) => irsaliyeOcr,
      projeOkumaRoute: (_) => const ProjeOkumaEkrani(),
    };
  }

  static void goSantiyeSecim(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(santiyeRoute, (_) => false);
  }

  static void goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(homeRoute, (_) => false);
  }

  static void goAuth(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(authRoute, (_) => false);
  }

  static Future<T?> push<T>(BuildContext context, String route) {
    return Navigator.of(context).pushNamed<T>(route);
  }
}
