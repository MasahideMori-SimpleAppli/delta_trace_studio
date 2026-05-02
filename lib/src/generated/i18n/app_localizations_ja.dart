// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get aboutApp => 'DeltaTraceDBについて';

  @override
  String get license => 'License';

  @override
  String get changeLanguage => 'English';

  @override
  String get enterQueryCode =>
      'IDEで作成したクエリを「debugPrint(jsonEncode(query.toDict()))」した結果を貼り付けると実行できます。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => '決定';

  @override
  String get close => '閉じる';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get dialog_fileFormatTitle => 'ファイル形式を選択';

  @override
  String get dialog_loadJson => 'JSON（平文）として読み込む';

  @override
  String get dialog_decryptAesGcm => 'AES-GCM（暗号化）として復号する';

  @override
  String get dialog_aesGcmTitle => 'AES-GCM の HEX キー入力';

  @override
  String get exportDatabaseTitle => 'エクスポート設定';

  @override
  String get exportDatabaseDescription => 'ファイル名の生成方法を選択してください。';

  @override
  String get useLocalTime => 'ローカルタイムを使用';

  @override
  String get useLocalTimeSubtitle => 'オンにすると、現在のローカル時刻でファイル名を生成します。';

  @override
  String get useMicroseconds => 'マイクロ秒を使用';

  @override
  String get useMicrosecondsSubtitle => 'オンにすると、ファイル名にマイクロ秒(6桁)を含めます。';

  @override
  String get useAesGcm => 'AES-GCM で暗号化する';

  @override
  String get useAesGcmSubtitle => 'オンにすると、AES-GCM を使用して暗号化して保存します。';

  @override
  String get dbData => 'DB データ';

  @override
  String get viewModeLabel => '表示モード:';

  @override
  String get viewModeList => 'リスト';

  @override
  String get viewModeTree => 'ツリー';

  @override
  String get viewModeQuery => 'クエリ';

  @override
  String get importDb => 'DB 読み込み';

  @override
  String get exportDb => 'DB 書き出し';

  @override
  String get decryptFile => 'ファイル復号';

  @override
  String get decryptResultTitle => '復号結果';

  @override
  String get noDbLoaded => 'データベースが読み込まれていません。';

  @override
  String get importDbHint => '.dtdb ファイルをインポートして開始してください。';

  @override
  String get treeSampling => 'サンプリング:';

  @override
  String get treeTextLength => 'テキスト長:';

  @override
  String get noData => 'データなし。';

  @override
  String get listTarget => 'ターゲット:';

  @override
  String get listPerPage => '表示件数:';

  @override
  String get listPleaseSelect => '選択してください';

  @override
  String get listPleaseSelectCollection => 'コレクションを選択してください。';

  @override
  String get listSearchHint => '検索（全キーを全文検索）';

  @override
  String get listSortBy => 'ソート:';

  @override
  String get sortAscending => '昇順';

  @override
  String get sortDescending => '降順';

  @override
  String listItemCount(int count) {
    return '$count件';
  }

  @override
  String listItemCountFiltered(int filtered, int total) {
    return '$filtered / $total件';
  }

  @override
  String get filterKeyRequired => 'フィルターを有効にする場合はキーを入力してください。';

  @override
  String get exportSuccess => 'DB を保存しました。';

  @override
  String get aesKeyLengthError => 'キーは 32、48、64 文字のいずれかで入力してください。';

  @override
  String get themeDark => 'ダークモードに切り替え';

  @override
  String get themeLight => 'ライトモードに切り替え';

  @override
  String get listFilter => 'フィルター';

  @override
  String get listMerge => 'マージ';

  @override
  String get listRemoveCollection => 'コレクション削除';

  @override
  String get listConfirmTitle => '確認';

  @override
  String get listConfirmRemoveBody => '表示中のコレクションをデータベースから削除します。\nよろしいですか？';

  @override
  String get listOperationFailed => '操作が失敗しました。';

  @override
  String get listEditJson => 'JSON を編集';

  @override
  String get listInvalidJson => 'JSON の形式が不正です';

  @override
  String get listCopied => 'クリップボードにコピーしました';

  @override
  String get dateFilterTitle => '日時フィルター';

  @override
  String get dateFilterKey => 'キー名';

  @override
  String get dateFilterKeyHint => 'キーを選択';

  @override
  String get dateFilterStart => '開始';

  @override
  String get dateFilterEnd => '終了';

  @override
  String get dateFilterClear => 'クリア';

  @override
  String get dateFilterNotSet => '未設定';

  @override
  String get dateFilterUseLocalTime => 'ローカル時間で計算';

  @override
  String get filterTitle => 'フィルター';

  @override
  String get filterDescription => '最大2つのフィルターを追加できます。有効化したフィルターはAnd条件で適用されます。';

  @override
  String get filterKeyLabel => 'キー';

  @override
  String get filterValueLabel => '値';

  @override
  String get filterTypeError => 'TypeError: 入力値を指定の型に変換できませんでした。';

  @override
  String get filterOpRegex => '正規表現';

  @override
  String get filterOpContains => 'Contains';

  @override
  String get filterOpIn => 'In';

  @override
  String get filterOpNotIn => 'Not in';

  @override
  String get filterOpStartsWith => '前方一致';

  @override
  String get filterOpEndsWith => '後方一致';

  @override
  String get queryLabel => 'クエリ (JSON)';

  @override
  String get runQuery => 'クエリを実行';

  @override
  String get querySucceeded => 'クエリが成功しました。';

  @override
  String get queryFailed => 'クエリが失敗しました。';

  @override
  String get resultLabel => '結果';

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました。';
}
