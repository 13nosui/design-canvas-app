import 'package:flutter_test/flutter_test.dart';
import 'package:design_canvas_app/presentation/pages/import_payload_controller.dart';

Map<String, dynamic> _samplePayload() => <String, dynamic>{
      'title': 'タスク管理',
      'icon': '🎯',
      'summary': '今日のタスクを俯瞰する',
      'prompt': '元プロンプト',
      'meta': <Map<String, dynamic>>[],
      'detail': <String, dynamic>{
        'screens': <Map<String, dynamic>>[
          {
            'name': 'ダッシュボード',
            'purpose': '今日のタスクを俯瞰',
            'sections': <Map<String, dynamic>>[
              {'label': 'アクション', 'body': '追加する'},
            ],
          },
        ],
        'userFlow': 'ユーザーは...',
        'apis': <Map<String, dynamic>>[],
        'stack': <String>['Next.js'],
        'risks': <String>['スケール'],
      },
    };

void main() {
  group('initial state', () {
    test('null payload allowed', () {
      final c = ImportPayloadController(null);
      expect(c.payload, isNull);
      expect(c.dirty, isFalse);
      expect(c.canUndo, isFalse);
      expect(c.canRedo, isFalse);
    });

    test('provided payload is set and dirty=false', () {
      final c = ImportPayloadController(_samplePayload());
      expect(c.payload, isNotNull);
      expect(c.payload!['title'], 'タスク管理');
      expect(c.dirty, isFalse);
      expect(c.canUndo, isFalse);
    });
  });

  group('editAtPath', () {
    test('updates top-level field and marks dirty', () {
      final c = ImportPayloadController(_samplePayload());
      var notified = 0;
      c.addListener(() => notified++);

      c.editAtPath(['title'], '新しいタイトル');

      expect(c.payload!['title'], '新しいタイトル');
      expect(c.dirty, isTrue);
      expect(notified, 1);
    });

    test('updates nested field via path', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(['detail', 'screens', 0, 'name'], 'ホーム');
      final screens = c.payload!['detail']['screens'] as List;
      expect((screens[0] as Map)['name'], 'ホーム');
    });

    test('updates nested section field', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(
          ['detail', 'screens', 0, 'sections', 0, 'body'], '書き換えた');
      final body = ((c.payload!['detail']['screens'] as List)[0]
          as Map)['sections'][0]['body'];
      expect(body, '書き換えた');
    });

    test('editAtPath pushes to undo stack', () {
      final c = ImportPayloadController(_samplePayload());
      expect(c.canUndo, isFalse);
      c.editAtPath(['title'], 'A');
      expect(c.canUndo, isTrue);
      c.editAtPath(['title'], 'B');
      c.editAtPath(['title'], 'C');
      // 3 edits → 3 undo entries
      expect(c.canUndo, isTrue);
    });

    test('null payload is a no-op', () {
      final c = ImportPayloadController(null);
      c.editAtPath(['title'], 'x');
      expect(c.payload, isNull);
    });

    test('empty path is a no-op', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(const [], 'x');
      expect(c.payload!['title'], 'タスク管理');
    });
  });

  group('undo/redo', () {
    test('undo reverts the last edit', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(['title'], '変更1');
      expect(c.payload!['title'], '変更1');
      c.undo();
      expect(c.payload!['title'], 'タスク管理');
      expect(c.canRedo, isTrue);
    });

    test('redo re-applies an undone edit', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(['title'], '変更1');
      c.undo();
      c.redo();
      expect(c.payload!['title'], '変更1');
    });

    test('new edit clears the redo stack', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(['title'], 'A');
      c.editAtPath(['title'], 'B');
      c.undo();
      expect(c.canRedo, isTrue);
      c.editAtPath(['title'], 'C');
      expect(c.canRedo, isFalse);
    });

    test('undo is deep-clone safe (does not share refs)', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(['detail', 'screens', 0, 'name'], 'X');
      c.undo();
      // Mutating the undone state should not affect the current payload
      final restoredName =
          ((c.payload!['detail']['screens'] as List)[0] as Map)['name'];
      expect(restoredName, 'ダッシュボード');
    });

    test('history bounded at 30', () {
      final c = ImportPayloadController(_samplePayload());
      for (var i = 0; i < 40; i++) {
        c.editAtPath(['title'], 'edit-$i');
      }
      // Undo 30 times should still work, 31st is null-op
      for (var i = 0; i < 30; i++) {
        c.undo();
      }
      // After 30 undos, cannot undo further (oldest kicked out)
      expect(c.canUndo, isFalse);
    });

    test('empty undo stack is a no-op', () {
      final c = ImportPayloadController(_samplePayload());
      c.undo(); // no-op
      expect(c.payload!['title'], 'タスク管理');
    });
  });

  group('startBlank', () {
    test('creates a template from null payload', () {
      final c = ImportPayloadController(null);
      c.startBlank();
      expect(c.payload, isNotNull);
      expect(c.payload!['title'], '新規プロジェクト');
      expect(c.payload!['icon'], '✨');
      expect(c.dirty, isTrue);
      final screens = c.payload!['detail']['screens'] as List;
      expect(screens, hasLength(1));
      final firstScreen = screens.first as Map;
      expect(firstScreen['name'], 'ホーム');
      expect((firstScreen['sections'] as List), hasLength(2));
    });

    test('replaces existing payload when called', () {
      final c = ImportPayloadController(_samplePayload());
      c.startBlank();
      expect(c.payload!['title'], '新規プロジェクト');
      // Previous payload is in undo stack
      c.undo();
      expect(c.payload!['title'], 'タスク管理');
    });
  });

  group('structural mutations', () {
    test('addScreen appends and undo removes', () {
      final c = ImportPayloadController(_samplePayload());
      c.addScreen();
      final screens = c.payload!['detail']['screens'] as List;
      expect(screens, hasLength(2));
      expect((screens.last as Map)['name'], '新規画面');
      c.undo();
      expect((c.payload!['detail']['screens'] as List), hasLength(1));
    });

    test('removeScreen drops by index', () {
      final c = ImportPayloadController(_samplePayload());
      c.addScreen();
      c.addScreen();
      expect((c.payload!['detail']['screens'] as List), hasLength(3));
      c.removeScreen(1);
      expect((c.payload!['detail']['screens'] as List), hasLength(2));
    });

    test('addSection extends the nested sections', () {
      final c = ImportPayloadController(_samplePayload());
      c.addSection(0);
      final sections = ((c.payload!['detail']['screens'] as List)[0]
          as Map)['sections'] as List;
      expect(sections, hasLength(2));
      expect((sections.last as Map)['label'], 'ラベル');
    });

    test('removeSection drops the nested section', () {
      final c = ImportPayloadController(_samplePayload());
      c.addSection(0);
      c.removeSection(0, 1);
      final sections = ((c.payload!['detail']['screens'] as List)[0]
          as Map)['sections'] as List;
      expect(sections, hasLength(1));
    });

    test('addApi / removeApi', () {
      final c = ImportPayloadController(_samplePayload());
      c.addApi();
      expect((c.payload!['detail']['apis'] as List), hasLength(1));
      c.removeApi(0);
      expect((c.payload!['detail']['apis'] as List), isEmpty);
    });

    test('addStack / removeStack', () {
      final c = ImportPayloadController(_samplePayload());
      // starts with 1 item: Next.js
      c.addStack();
      expect((c.payload!['detail']['stack'] as List), hasLength(2));
      c.removeStack(0);
      expect((c.payload!['detail']['stack'] as List), hasLength(1));
    });

    test('addRisk / removeRisk', () {
      final c = ImportPayloadController(_samplePayload());
      // starts with 1 item: スケール
      c.addRisk();
      expect((c.payload!['detail']['risks'] as List), hasLength(2));
      c.removeRisk(1);
      expect((c.payload!['detail']['risks'] as List), hasLength(1));
    });

    test('removeScreen on invalid index is a no-op', () {
      final c = ImportPayloadController(_samplePayload());
      c.removeScreen(99);
      expect((c.payload!['detail']['screens'] as List), hasLength(1));
    });
  });

  group('meta badges', () {
    test('addMeta appends', () {
      final c = ImportPayloadController(_samplePayload());
      expect((c.payload!['meta'] as List), isEmpty);
      c.addMeta();
      final meta = c.payload!['meta'] as List;
      expect(meta, hasLength(1));
      expect((meta[0] as Map)['label'], 'ラベル');
      expect((meta[0] as Map)['color'], 'slate');
    });

    test('removeMeta drops by index', () {
      final c = ImportPayloadController(_samplePayload());
      c.addMeta();
      c.addMeta();
      c.removeMeta(0);
      expect((c.payload!['meta'] as List), hasLength(1));
    });

    test('cycleMetaColor rotates through the 4 colors', () {
      final c = ImportPayloadController(_samplePayload());
      c.addMeta();
      expect(((c.payload!['meta'] as List)[0] as Map)['color'], 'slate');
      c.cycleMetaColor(0);
      // metaColors is [green, blue, yellow, slate]; from slate index 3 → 0 → green
      expect(((c.payload!['meta'] as List)[0] as Map)['color'], 'green');
      c.cycleMetaColor(0);
      expect(((c.payload!['meta'] as List)[0] as Map)['color'], 'blue');
      c.cycleMetaColor(0);
      expect(((c.payload!['meta'] as List)[0] as Map)['color'], 'yellow');
      c.cycleMetaColor(0);
      expect(((c.payload!['meta'] as List)[0] as Map)['color'], 'slate');
    });

    test('cycleMetaColor on invalid index is a no-op', () {
      final c = ImportPayloadController(_samplePayload());
      c.cycleMetaColor(99);
      expect((c.payload!['meta'] as List), isEmpty);
    });
  });

  group('exportAsJson / importFromJson', () {
    test('exportAsJson returns pretty-printed JSON', () {
      final c = ImportPayloadController(_samplePayload());
      final jsonStr = c.exportAsJson();
      expect(jsonStr, contains('"title": "タスク管理"'));
      expect(jsonStr, contains('\n')); // indented, multi-line
    });

    test('exportAsJson on null payload returns empty', () {
      final c = ImportPayloadController(null);
      expect(c.exportAsJson(), '');
    });

    test('importFromJson replaces the payload', () {
      final c = ImportPayloadController(_samplePayload());
      final ok = c.importFromJson('{"title": "新しい", "detail": {}}');
      expect(ok, isTrue);
      expect(c.payload!['title'], '新しい');
      expect(c.dirty, isTrue);
    });

    test('importFromJson pushes to history (undo restores)', () {
      final c = ImportPayloadController(_samplePayload());
      c.importFromJson('{"title": "差替"}');
      c.undo();
      expect(c.payload!['title'], 'タスク管理');
    });

    test('importFromJson rejects malformed input', () {
      final c = ImportPayloadController(_samplePayload());
      expect(c.importFromJson('not json at all'), isFalse);
      expect(c.payload!['title'], 'タスク管理'); // unchanged
    });

    test('importFromJson rejects non-object top level', () {
      final c = ImportPayloadController(_samplePayload());
      expect(c.importFromJson('[1, 2, 3]'), isFalse);
      expect(c.importFromJson('"just a string"'), isFalse);
    });

    test('exportAsJson -> importFromJson round-trip', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(['title'], '編集後');
      final exported = c.exportAsJson();

      final c2 = ImportPayloadController(null);
      final ok = c2.importFromJson(exported);
      expect(ok, isTrue);
      expect(c2.payload!['title'], '編集後');
      expect(c2.payload!['detail']['screens'],
          c.payload!['detail']['screens']);
    });
  });

  group('dispose', () {
    test('does not throw', () {
      final c = ImportPayloadController(_samplePayload());
      c.editAtPath(['title'], 'x');
      c.dispose();
    });
  });
}
