import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About DeltaTraceDB'**
  String get aboutApp;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get changeLanguage;

  /// No description provided for @enterQueryCode.
  ///
  /// In en, this message translates to:
  /// **'You can paste the result of debugPrint(jsonEncode(query.toDict())) in your IDE here.'**
  String get enterQueryCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Title: Dialog allowing the user to select a file format
  ///
  /// In en, this message translates to:
  /// **'Select File Format'**
  String get dialog_fileFormatTitle;

  /// Menu item for loading plaintext JSON
  ///
  /// In en, this message translates to:
  /// **'Load as JSON (plaintext)'**
  String get dialog_loadJson;

  /// Menu item for decrypting using AES-GCM
  ///
  /// In en, this message translates to:
  /// **'Decrypt as AES-GCM (encrypted)'**
  String get dialog_decryptAesGcm;

  /// Title: Prompts the user to enter the HEX key
  ///
  /// In en, this message translates to:
  /// **'Enter AES-GCM HEX Key'**
  String get dialog_aesGcmTitle;

  /// No description provided for @exportDatabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Settings'**
  String get exportDatabaseTitle;

  /// No description provided for @exportDatabaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Select how the file name should be generated.'**
  String get exportDatabaseDescription;

  /// No description provided for @useLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Use local time'**
  String get useLocalTime;

  /// No description provided for @useLocalTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If enabled, the local time will be used in the file name.'**
  String get useLocalTimeSubtitle;

  /// No description provided for @useMicroseconds.
  ///
  /// In en, this message translates to:
  /// **'Use microseconds'**
  String get useMicroseconds;

  /// No description provided for @useMicrosecondsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If enabled, the file name will include microseconds (6 digits).'**
  String get useMicrosecondsSubtitle;

  /// No description provided for @useAesGcm.
  ///
  /// In en, this message translates to:
  /// **'Encrypt with AES-GCM'**
  String get useAesGcm;

  /// No description provided for @useAesGcmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If enabled, the data will be encrypted with AES-GCM.'**
  String get useAesGcmSubtitle;

  /// No description provided for @dbData.
  ///
  /// In en, this message translates to:
  /// **'DB Data'**
  String get dbData;

  /// No description provided for @viewModeLabel.
  ///
  /// In en, this message translates to:
  /// **'View mode:'**
  String get viewModeLabel;

  /// No description provided for @viewModeList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewModeList;

  /// No description provided for @viewModeTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get viewModeTree;

  /// No description provided for @viewModeQuery.
  ///
  /// In en, this message translates to:
  /// **'Query'**
  String get viewModeQuery;

  /// No description provided for @importDb.
  ///
  /// In en, this message translates to:
  /// **'Import DB'**
  String get importDb;

  /// No description provided for @exportDb.
  ///
  /// In en, this message translates to:
  /// **'Export DB'**
  String get exportDb;

  /// No description provided for @decryptFile.
  ///
  /// In en, this message translates to:
  /// **'Decrypt file'**
  String get decryptFile;

  /// No description provided for @decryptResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Decrypted content'**
  String get decryptResultTitle;

  /// No description provided for @noDbLoaded.
  ///
  /// In en, this message translates to:
  /// **'No database loaded.'**
  String get noDbLoaded;

  /// No description provided for @importDbHint.
  ///
  /// In en, this message translates to:
  /// **'Import a .dtdb file to get started.'**
  String get importDbHint;

  /// No description provided for @treeSampling.
  ///
  /// In en, this message translates to:
  /// **'Sampling:'**
  String get treeSampling;

  /// No description provided for @treeTextLength.
  ///
  /// In en, this message translates to:
  /// **'Text length:'**
  String get treeTextLength;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data.'**
  String get noData;

  /// No description provided for @listTarget.
  ///
  /// In en, this message translates to:
  /// **'Target:'**
  String get listTarget;

  /// No description provided for @listPerPage.
  ///
  /// In en, this message translates to:
  /// **'Per page:'**
  String get listPerPage;

  /// No description provided for @listPleaseSelect.
  ///
  /// In en, this message translates to:
  /// **'Please select'**
  String get listPleaseSelect;

  /// No description provided for @listPleaseSelectCollection.
  ///
  /// In en, this message translates to:
  /// **'Please select target collection.'**
  String get listPleaseSelectCollection;

  /// No description provided for @listSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search (full-text across all keys)'**
  String get listSearchHint;

  /// No description provided for @listSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort:'**
  String get listSortBy;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @listItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String listItemCount(int count);

  /// No description provided for @listItemCountFiltered.
  ///
  /// In en, this message translates to:
  /// **'{filtered} / {total} items'**
  String listItemCountFiltered(int filtered, int total);

  /// No description provided for @filterKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Key is required when filter is enabled.'**
  String get filterKeyRequired;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'DB saved successfully.'**
  String get exportSuccess;

  /// No description provided for @aesKeyLengthError.
  ///
  /// In en, this message translates to:
  /// **'Key must be 32, 48, or 64 characters.'**
  String get aesKeyLengthError;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get themeLight;

  /// No description provided for @listFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get listFilter;

  /// No description provided for @listMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get listMerge;

  /// No description provided for @listRemoveCollection.
  ///
  /// In en, this message translates to:
  /// **'Remove collection'**
  String get listRemoveCollection;

  /// No description provided for @listConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get listConfirmTitle;

  /// No description provided for @listConfirmRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The displayed collection will be deleted from the database.\nAre you sure?'**
  String get listConfirmRemoveBody;

  /// No description provided for @listOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The operation failed.'**
  String get listOperationFailed;

  /// No description provided for @listEditJson.
  ///
  /// In en, this message translates to:
  /// **'Edit JSON'**
  String get listEditJson;

  /// No description provided for @listInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON format'**
  String get listInvalidJson;

  /// No description provided for @listCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get listCopied;

  /// No description provided for @dateFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Date/time filter'**
  String get dateFilterTitle;

  /// No description provided for @dateFilterKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get dateFilterKey;

  /// No description provided for @dateFilterKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Select a key'**
  String get dateFilterKeyHint;

  /// No description provided for @dateFilterStart.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dateFilterStart;

  /// No description provided for @dateFilterEnd.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dateFilterEnd;

  /// No description provided for @dateFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dateFilterClear;

  /// No description provided for @dateFilterNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get dateFilterNotSet;

  /// No description provided for @dateFilterUseLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Use local time'**
  String get dateFilterUseLocalTime;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterDescription.
  ///
  /// In en, this message translates to:
  /// **'Up to 2 filters can be added. Enabled filters are applied with AND condition.'**
  String get filterDescription;

  /// No description provided for @filterKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'key'**
  String get filterKeyLabel;

  /// No description provided for @filterValueLabel.
  ///
  /// In en, this message translates to:
  /// **'value'**
  String get filterValueLabel;

  /// No description provided for @filterTypeError.
  ///
  /// In en, this message translates to:
  /// **'TypeError: The input could not be converted to the specified type.'**
  String get filterTypeError;

  /// No description provided for @filterOpRegex.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get filterOpRegex;

  /// No description provided for @filterOpContains.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get filterOpContains;

  /// No description provided for @filterOpIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get filterOpIn;

  /// No description provided for @filterOpNotIn.
  ///
  /// In en, this message translates to:
  /// **'Not in'**
  String get filterOpNotIn;

  /// No description provided for @filterOpStartsWith.
  ///
  /// In en, this message translates to:
  /// **'Starts with'**
  String get filterOpStartsWith;

  /// No description provided for @filterOpEndsWith.
  ///
  /// In en, this message translates to:
  /// **'Ends with'**
  String get filterOpEndsWith;

  /// No description provided for @queryLabel.
  ///
  /// In en, this message translates to:
  /// **'Query (JSON)'**
  String get queryLabel;

  /// No description provided for @runQuery.
  ///
  /// In en, this message translates to:
  /// **'Run query'**
  String get runQuery;

  /// No description provided for @querySucceeded.
  ///
  /// In en, this message translates to:
  /// **'Query succeeded.'**
  String get querySucceeded;

  /// No description provided for @queryFailed.
  ///
  /// In en, this message translates to:
  /// **'Query failed.'**
  String get queryFailed;

  /// No description provided for @resultLabel.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultLabel;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard.'**
  String get copiedToClipboard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
