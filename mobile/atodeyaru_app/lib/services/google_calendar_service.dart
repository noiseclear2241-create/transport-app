import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Googleカレンダー連携（プレミアム限定、#27, #28）。
///
/// 重要：常時同期・定期ポーリングは行わない。予定の追加・変更・削除の
/// タイミングでのみAPIを呼び出す「手動同期」に限定し、サーバー/APIコストを
/// 抑える（#28）。Googleアカウントのパスワードは保存しない（#27, #48）。
///
/// 利用にはGoogle Cloud ConsoleでOAuthクライアントIDを発行し、
/// iOS/Androidそれぞれのgoogle-services設定を追加する必要がある（未設定の間は
/// isConfigured が false を返し、UI側で案内を表示する）。
class GoogleCalendarService {
  GoogleCalendarService._internal();
  static final GoogleCalendarService instance = GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarEventsScope],
  );

  GoogleSignInAccount? _account;

  bool get isConnected => _account != null;

  Future<GoogleSignInAccount?> connect() async {
    _account = await _googleSignIn.signIn();
    return _account;
  }

  Future<void> disconnect() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  Future<calendar.CalendarApi?> _apiClient() async {
    final account = _account;
    if (account == null) return null;
    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return calendar.CalendarApi(client);
  }

  /// タスク1件をGoogleカレンダーへ追加/更新する（イベント追加・変更時のみ呼ぶ）。
  Future<String?> upsertEvent(TaskItem task, {String? existingEventId}) async {
    final api = await _apiClient();
    if (api == null) return null;

    final event = calendar.Event(
      summary: '${task.type.emoji} ${task.title}',
      description: task.subtitle,
      start: calendar.EventDateTime(date: DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day)),
      end: calendar.EventDateTime(date: DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day + 1)),
    );

    if (existingEventId != null) {
      final updated = await api.events.update(event, 'primary', existingEventId);
      return updated.id;
    }
    final created = await api.events.insert(event, 'primary');
    return created.id;
  }

  /// タスク削除時のみ呼ぶ（#28）。
  Future<void> deleteEvent(String eventId) async {
    final api = await _apiClient();
    if (api == null) return;
    await api.events.delete('primary', eventId);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
