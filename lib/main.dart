import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/drawer/util_drawer.dart';
import 'package:delta_trace_studio/ui/pages/main_page/main_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_locale/simple_locale.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/Noto_Sans_JP/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(
    LocalizedApp(
      supportedLocales: AppLocalizations.supportedLocales,
      child: const DeltaTraceStudioApp(),
    ),
  );
}

class DeltaTraceStudioApp extends StatelessWidget {
  const DeltaTraceStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: LocaleManager.of(context)?.getLocaleForApp(),
      title: 'DeltaTrace Studio',
      theme: ThemeData(
        fontFamily: "Noto Sans JP",
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DeltaTraceStudioHome(),
    );
  }
}

class DeltaTraceStudioHome extends StatefulWidget {
  const DeltaTraceStudioHome({super.key});

  @override
  State<DeltaTraceStudioHome> createState() => _DeltaTraceStudioHomeState();
}

class _DeltaTraceStudioHomeState extends State<DeltaTraceStudioHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DeltaTrace Studio')),
      drawer: UtilDrawer.createDrawer(context),
      body: MainPage(),
    );
  }
}
