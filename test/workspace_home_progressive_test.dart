import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_android/core/models/connection.dart';
import 'package:hermes_android/core/screens/workspace_screen.dart';
import 'package:hermes_android/core/screens/workspace_sessions_screen.dart';
import 'package:hermes_android/core/services/local_chat_pin_store.dart';
import 'package:hermes_android/core/services/quick_chat_store.dart';
import 'package:hermes_android/core/theme/hermes_theme.dart';
import 'package:hermes_android/core/utils/home_turn_signals.dart';
import 'package:hermes_android/core/widgets/hermes_components.dart';

import 'package:hermes_android/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> _row(int index, {bool pinned = false}) => {
  'id': 'session-$index',
  'title': index == 101 ? 'Late unassigned' : 'Chat $index',
  'model': 'test',
  'source': 'gateway',
  'message_count': 1,
  'started_at': DateTime.now().millisecondsSinceEpoch / 1000.0 - index,
  'pinned': pinned,
};

http.Response _page(List<Map<String, Object?>> rows) => http.Response(
  jsonEncode({'object': 'list', 'data': rows, 'has_more': false}),
  200,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'five-row Home renders before later page; old work and Chats complete',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final laterPage = Completer<http.Response>();
      final requested = <Uri>[];
      final client = MockClient((request) async {
        requested.add(request.url);
        final limit = request.url.queryParameters['limit'];
        final offset = request.url.queryParameters['offset'];
        if (limit == '5') {
          // Stock can append pinned rows outside the requested window.
          return _page([...List.generate(5, _row), _row(100, pinned: true)]);
        }
        if (offset == '0') {
          return _page([...List.generate(100, _row), _row(100, pinned: true)]);
        }
        if (offset == '100') return laterPage.future;
        return _page([]);
      });
      final connection = SavedConnection(
        id: 'progressive-test',
        label: 'Test',
        host: 'example.invalid',
        port: 8642,
        apiKey: 'test-key',
      );
      final preferences = await SharedPreferences.getInstance();
      final quick = QuickChatStore(preferences, connectionId: connection.id);
      await quick.record(
        'session-101',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      final pins = LocalChatPinStore(preferences, connectionId: connection.id);
      await pins.setPinned('session-101', pinned: true);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: hermesTheme(Brightness.dark),
          home: WorkspaceScreen(
            connection: connection,
            testSessionsHttpClient: client,
            turnSignalsLoader: (_) async => const HomeTurnSignals(
              attention: {'session-100': 'Approval required'},
              running: {'session-101'},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(requested.first.queryParameters['limit'], '5');
      expect(requested.first.queryParameters['offset'], '0');
      expect(find.text('Chat 0'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Chat 100'), findsNothing);
      expect(find.text('Late unassigned'), findsNothing);
      expect(find.byType(LoadingSkeleton), findsNothing);
      expect((await quick.load()).expiries, contains('session-101'));
      expect(await pins.load(), contains('session-101'));

      laterPage.complete(_page([_row(100, pinned: true), _row(101)]));
      await tester.pumpAndSettle();
      expect(
        requested.any((uri) => uri.queryParameters['offset'] == '100'),
        isTrue,
      );
      expect(find.text('Chat 100'), findsOneWidget);
      expect(find.text('Approval required'), findsOneWidget);
      expect(find.text('Late unassigned'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect((await quick.load()).expiries, contains('session-101'));
      expect(await pins.load(), contains('session-101'));

      await tester.tap(find.text('Chats').last);
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceSessionsScreen), findsOneWidget);
      // Search proves the old unassigned row is in the complete Chats dataset,
      // not just a Home-only background projection.
      await tester.enterText(
        find.byKey(kWorkspaceSessionSearchKey),
        'Late unassigned',
      );
      await tester.pumpAndSettle();
      expect(find.text('Late unassigned'), findsNWidgets(2));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Unassigned'));
      await tester.pumpAndSettle();
      expect(find.text('Late unassigned'), findsNWidgets(2));
    },
  );
}
