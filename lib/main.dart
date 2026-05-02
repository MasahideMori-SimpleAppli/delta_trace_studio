import 'package:delta_trace_db/delta_trace_db.dart';
import 'package:delta_trace_studio/src/generated/i18n/app_localizations.dart';
import 'package:delta_trace_studio/ui/drawer/util_drawer.dart';
import 'package:delta_trace_studio/ui/pages/main_page/main_page.dart';
import 'package:delta_trace_studio/ui/pages/main_page/query/query_with_time.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_locale/simple_locale.dart';

DeltaTraceDatabase localDB = DeltaTraceDatabase();
final List<QueryWithTime> appliedQueries = [];
String? selectedTarget;
String? dbFileName;

final queryTextController = TextEditingController();
final queryResultNotifier = ValueNotifier<String>("Empty.");
final aesGcmKeyController = TextEditingController();
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  // localDB.executeQuery(
  //   RawQueryBuilder.add(
  //     target: "server_logs",
  //     rawAddData: [
  //       {"id": 1, "level": "INFO",  "service": "auth", "message": "User logged in",           "timestamp": "2026-04-10T08:30:00.000Z"},
  //       {"id": 2, "level": "WARN",  "service": "api",  "message": "Slow response detected",   "timestamp": "2026-04-10T14:22:10.000Z"},
  //       {"id": 3, "level": "ERROR", "service": "db",   "message": "Connection timeout",        "timestamp": "2026-04-15T02:15:33.000Z"},
  //       {"id": 4, "level": "INFO",  "service": "auth", "message": "Token refreshed",           "timestamp": "2026-04-15T09:00:00.000Z"},
  //       {"id": 5, "level": "INFO",  "service": "api",  "message": "Request processed",         "timestamp": "2026-04-20T11:45:00.000Z"},
  //       {"id": 6, "level": "ERROR", "service": "auth", "message": "Invalid credentials",       "timestamp": "2026-04-20T16:30:00.000Z"},
  //       {"id": 7, "level": "WARN",  "service": "db",   "message": "High memory usage",         "timestamp": "2026-04-28T03:10:00.000Z"},
  //       {"id": 8, "level": "INFO",  "service": "api",  "message": "Cache cleared",             "timestamp": "2026-04-28T10:00:00.000Z"},
  //       {"id": 9, "level": "ERROR", "service": "db",   "message": "Replication lag detected",  "timestamp": "2026-05-01T20:00:00.000Z"},
  //       {"id": 10,"level": "INFO",  "service": "auth", "message": "User logged out",           "timestamp": "2026-05-02T08:00:00.000Z"},
  //     ],
  //   ).build(),
  // );
  // selectedTarget = "server_logs";
  // dbFileName = "sample_data (debug)";

  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final licenseJp = await rootBundle.loadString(
      'assets/fonts/Noto_Sans_JP/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['google_fonts'], licenseJp);
    final licenseMono = await rootBundle.loadString(
      'assets/fonts/Noto_Sans_Mono/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['google_fonts'], licenseMono);
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, themeMode, _) {
        return MaterialApp(
          locale: LocaleManager.of(context)?.getLocaleForApp(),
          title: 'DeltaTrace Studio',
          theme: ThemeData(
            fontFamily: "Noto Sans JP",
            colorSchemeSeed: Colors.teal,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            fontFamily: "Noto Sans JP",
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeltaTraceStudioHome(),
        );
      },
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
      appBar: AppBar(title: const Text('DeltaTraceStudio')),
      drawer: UtilDrawer.createDrawer(context),
      body: MainPage(),
    );
  }
}
