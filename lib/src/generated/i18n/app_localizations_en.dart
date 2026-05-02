// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutApp => 'About DeltaTraceDB';

  @override
  String get license => 'License';

  @override
  String get changeLanguage => '日本語';

  @override
  String get enterQueryCode =>
      'You can paste the result of debugPrint(jsonEncode(query.toDict())) in your IDE here.';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get dialog_fileFormatTitle => 'Select File Format';

  @override
  String get dialog_loadJson => 'Load as JSON (plaintext)';

  @override
  String get dialog_decryptAesGcm => 'Decrypt as AES-GCM (encrypted)';

  @override
  String get dialog_aesGcmTitle => 'Enter AES-GCM HEX Key';

  @override
  String get exportDatabaseTitle => 'Export Settings';

  @override
  String get exportDatabaseDescription =>
      'Select how the file name should be generated.';

  @override
  String get useLocalTime => 'Use local time';

  @override
  String get useLocalTimeSubtitle =>
      'If enabled, the local time will be used in the file name.';

  @override
  String get useMicroseconds => 'Use microseconds';

  @override
  String get useMicrosecondsSubtitle =>
      'If enabled, the file name will include microseconds (6 digits).';

  @override
  String get useAesGcm => 'Encrypt with AES-GCM';

  @override
  String get useAesGcmSubtitle =>
      'If enabled, the data will be encrypted with AES-GCM.';

  @override
  String get dbData => 'DB Data';

  @override
  String get viewModeLabel => 'View mode:';

  @override
  String get viewModeList => 'List';

  @override
  String get viewModeTree => 'Tree';

  @override
  String get viewModeQuery => 'Query';

  @override
  String get importDb => 'Import DB';

  @override
  String get exportDb => 'Export DB';

  @override
  String get decryptFile => 'Decrypt file';

  @override
  String get decryptResultTitle => 'Decrypted content';

  @override
  String get noDbLoaded => 'No database loaded.';

  @override
  String get importDbHint => 'Import a .dtdb file to get started.';

  @override
  String get treeSampling => 'Sampling:';

  @override
  String get treeTextLength => 'Text length:';

  @override
  String get noData => 'No data.';

  @override
  String get listTarget => 'Target:';

  @override
  String get listPerPage => 'Per page:';

  @override
  String get listPleaseSelect => 'Please select';

  @override
  String get listPleaseSelectCollection => 'Please select target collection.';

  @override
  String get listSearchHint => 'Search (full-text across all keys)';

  @override
  String get listSortBy => 'Sort:';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String listItemCount(int count) {
    return '$count items';
  }

  @override
  String listItemCountFiltered(int filtered, int total) {
    return '$filtered / $total items';
  }

  @override
  String get filterKeyRequired => 'Key is required when filter is enabled.';

  @override
  String get exportSuccess => 'DB saved successfully.';

  @override
  String get aesKeyLengthError => 'Key must be 32, 48, or 64 characters.';

  @override
  String get themeDark => 'Switch to dark mode';

  @override
  String get themeLight => 'Switch to light mode';

  @override
  String get listFilter => 'Filter';

  @override
  String get listMerge => 'Merge';

  @override
  String get listRemoveCollection => 'Remove collection';

  @override
  String get listConfirmTitle => 'Confirmation';

  @override
  String get listConfirmRemoveBody =>
      'The displayed collection will be deleted from the database.\nAre you sure?';

  @override
  String get listOperationFailed => 'The operation failed.';

  @override
  String get listEditJson => 'Edit JSON';

  @override
  String get listInvalidJson => 'Invalid JSON format';

  @override
  String get listCopied => 'Copied to clipboard';

  @override
  String get dateFilterTitle => 'Date/time filter';

  @override
  String get dateFilterKey => 'Key';

  @override
  String get dateFilterKeyHint => 'Select a key';

  @override
  String get dateFilterStart => 'From';

  @override
  String get dateFilterEnd => 'To';

  @override
  String get dateFilterClear => 'Clear';

  @override
  String get dateFilterNotSet => 'Not set';

  @override
  String get dateFilterUseLocalTime => 'Use local time';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterDescription =>
      'Up to 2 filters can be added. Enabled filters are applied with AND condition.';

  @override
  String get filterKeyLabel => 'key';

  @override
  String get filterValueLabel => 'value';

  @override
  String get filterTypeError =>
      'TypeError: The input could not be converted to the specified type.';

  @override
  String get filterOpRegex => 'Regex';

  @override
  String get filterOpContains => 'Contains';

  @override
  String get filterOpIn => 'In';

  @override
  String get filterOpNotIn => 'Not in';

  @override
  String get filterOpStartsWith => 'Starts with';

  @override
  String get filterOpEndsWith => 'Ends with';

  @override
  String get queryLabel => 'Query (JSON)';

  @override
  String get runQuery => 'Run query';

  @override
  String get querySucceeded => 'Query succeeded.';

  @override
  String get queryFailed => 'Query failed.';

  @override
  String get resultLabel => 'Result';

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get copiedToClipboard => 'Copied to clipboard.';
}
