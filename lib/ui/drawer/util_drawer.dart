import 'package:flutter/material.dart';
import 'package:simple_locale/simple_locale.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/f_app.dart';
import '../../src/generated/i18n/app_localizations.dart';

class UtilDrawer {
  /// return drawer
  static Widget createDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.teal,
            ),
            child: const Text(
              FApp.appName,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.aboutApp),
            onTap: () async {
              Navigator.pop(context);
              final Uri url =
                  Uri.parse("https://pub.dev/packages/delta_trace_db");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.changeLanguage),
            onTap: () async {
              if (context.mounted) {
                final Locale now = LocaleManager.of(context)?.getLocale() ??
                    const Locale("en");
                if (now == const Locale("en")) {
                  LocaleManager.of(context)?.changeLocale(const Locale("ja"));
                } else {
                  LocaleManager.of(context)?.changeLocale(const Locale("en"));
                }
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.license),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: FApp.appName,
                applicationVersion: FApp.appVersion,
                applicationLegalese: FApp.appLegalese,
              );
            },
          ),
        ],
      ),
    );
  }
}
