import 'package:flutter/material.dart';

import 'package:sefim/ekran/auth_ekrani.dart';
import 'package:sefim/ekran/proje_okuma_ekrani.dart';
import 'package:sefim/ekran/yapi_eleman_kontrolu_ekrani.dart';

abstract final class AppRouter {
  static const authRoute = '/auth';
  static const homeRoute = '/';
  static const irsaliyeRoute = '/irsaliye-ocr';
  static const yapiElemaniRoute = '/yapi-eleman-kontrolu';
  static const projeOkumaRoute = '/proje-okuma';

  static Map<String, WidgetBuilder> routes({
    required Widget home,
    required Widget irsaliyeOcr,
    required void Function(BuildContext context) onAuthenticated,
  }) {
    return {
      authRoute: (context) => AuthEkrani(onAuthenticated: onAuthenticated),
      homeRoute: (_) => home,
      irsaliyeRoute: (_) => irsaliyeOcr,
      yapiElemaniRoute: (_) => const YapiElemanKontroluEkrani(),
      projeOkumaRoute: (_) => const ProjeOkumaEkrani(),
    };
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
