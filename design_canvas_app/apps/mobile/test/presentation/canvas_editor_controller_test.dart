// Pure-Dart tests for CanvasEditorController. We use a hand-written
// FakeCanvasInspectorClient so the test suite has no dependency on HTTP,
// dart:io, or Flutter bindings beyond flutter_test (which runs under
// `flutter test`). The same approach is used by ImportPayloadController
// tests — see ADR-0007.

import 'package:flutter_test/flutter_test.dart';
import 'package:design_canvas_app/presentation/pages/canvas_editor_controller.dart';
import 'package:design_canvas_app/presentation/pages/canvas_inspector_client.dart';

class FakeCanvasInspectorClient implements CanvasInspectorClient {
  final List<String> calls = [];

  // Programmable per-endpoint responses. Tests that want a failure
  // swap the default ok response before calling the controller.
  InspectorResult parseResponse =
      const InspectorResult.ok(data: {'fields': []});
  InspectorResult mutationResponse = const InspectorResult.ok();

  @override
  Future<InspectorResult> parse(String stylesPath) async {
    calls.add('parse:$stylesPath');
    return parseResponse;
  }

  @override
  Future<InspectorResult> updateStyle({
    required String path,
    required String? className,
    required String name,
    required String value,
  }) async {
    calls.add('updateStyle:$path:$className:$name:$value');
    return mutationResponse;
  }

  @override
  Future<InspectorResult> promoteToken({
    required String path,
    required String? className,
    required String name,
    required String tokenName,
    required String value,
  }) async {
    calls.add('promoteToken:$path:$className:$name:$tokenName:$value');
    return mutationResponse;
  }

  @override
  Future<InspectorResult> replaceText({
    required String path,
    required String id,
    required String text,
  }) async {
    calls.add('replaceText:$path:$id:$text');
    return mutationResponse;
  }

  @override
  Future<InspectorResult> wrap({
    required String path,
    required String id,
    required String wrapper,
  }) async {
    calls.add('wrap:$path:$id:$wrapper');
    return mutationResponse;
  }

  @override
  Future<InspectorResult> unwrap({
    required String path,
    required String id,
  }) async {
    calls.add('unwrap:$path:$id');
    return mutationResponse;
  }

  @override
  Future<InspectorResult> duplicate({
    required String path,
    required String id,
  }) async {
    calls.add('duplicate:$path:$id');
    return mutationResponse;
  }

  @override
  Future<InspectorResult> insert({
    required String path,
    required String id,
  }) async {
    calls.add('insert:$path:$id');
    return mutationResponse;
  }
}

Future<List<CanvasEditorEvent>> _collectEvents(
  CanvasEditorController c,
  Future<void> Function() action,
) async {
  final events = <CanvasEditorEvent>[];
  final sub = c.events.listen(events.add);
  await action();
  // Give broadcast listeners a microtask to drain.
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return events;
}

void main() {
  late FakeCanvasInspectorClient client;
  late CanvasEditorController controller;

  setUp(() {
    client = FakeCanvasInspectorClient();
    controller = CanvasEditorController(client: client);
  });

  tearDown(() => controller.dispose());

  group('initial state', () {
    test('starts empty', () {
      expect(controller.inspectedFilePath, isNull);
      expect(controller.inspectedFields, isEmpty);
      expect(controller.isInspectorLoading, isFalse);
    });
  });

  group('loadInspector', () {
    test('converts .dart path to .styles.dart and populates fields', () async {
      client.parseResponse = const InspectorResult.ok(data: {
        'fields': [
          {'name': 'padding', 'value': '8'},
        ],
      });

      await controller.loadInspector('lib/foo/bar_page.dart');

      expect(controller.inspectedFilePath, 'lib/foo/bar_page.styles.dart');
      expect(controller.inspectedFields, hasLength(1));
      expect(controller.isInspectorLoading, isFalse);
      expect(client.calls, ['parse:lib/foo/bar_page.styles.dart']);
    });

    test('handles parse failure by resetting loading flag', () async {
      client.parseResponse = const InspectorResult.failure('boom');
      await controller.loadInspector('lib/foo/bar_page.dart');
      expect(controller.isInspectorLoading, isFalse);
      expect(controller.inspectedFields, isEmpty);
    });

    test('notifies listeners at least twice (start + end of load)', () async {
      var notified = 0;
      controller.addListener(() => notified++);
      await controller.loadInspector('lib/foo/bar_page.dart');
      expect(notified, greaterThanOrEqualTo(2));
    });
  });

  group('updateStyleField', () {
    test('no-op when no file is inspected', () async {
      await controller.updateStyleField(null, 'padding', '12');
      expect(client.calls, isEmpty);
    });

    test('calls updateStyle then re-parses and emits success', () async {
      await controller.loadInspector('lib/foo/bar_page.dart');
      client.calls.clear();

      final events = await _collectEvents(
        controller,
        () => controller.updateStyleField('BarStyles', 'padding', '12'),
      );

      expect(client.calls, [
        'updateStyle:lib/foo/bar_page.styles.dart:BarStyles:padding:12',
        'parse:lib/foo/bar_page.styles.dart',
      ]);
      expect(events, hasLength(1));
      expect(events.first, isA<CanvasEditorSuccess>());
    });

    test('emits error on failure, skips re-parse', () async {
      await controller.loadInspector('lib/foo/bar_page.dart');
      client.calls.clear();
      client.mutationResponse = const InspectorResult.failure('nope');

      final events = await _collectEvents(
        controller,
        () => controller.updateStyleField(null, 'padding', '12'),
      );

      expect(
          client.calls,
          ['updateStyle:lib/foo/bar_page.styles.dart:null:padding:12']);
      expect(events.single, isA<CanvasEditorError>());
    });
  });

  group('promoteToken', () {
    test('skips when tokenName is null', () async {
      await controller.loadInspector('lib/foo/bar_page.dart');
      client.calls.clear();
      await controller.promoteToken('BarStyles', 'padding', null, '12');
      expect(client.calls, isEmpty);
    });

    test('calls promoteToken then re-parses on success', () async {
      await controller.loadInspector('lib/foo/bar_page.dart');
      client.calls.clear();

      final events = await _collectEvents(
        controller,
        () => controller.promoteToken(
            'BarStyles', 'padding', 'spaceM', '12'),
      );

      expect(client.calls, [
        'promoteToken:lib/foo/bar_page.styles.dart:BarStyles:padding:spaceM:12',
        'parse:lib/foo/bar_page.styles.dart',
      ]);
      expect(events.single, isA<CanvasEditorSuccess>());
    });
  });

  group('updateCodeText', () {
    test('uses fallback path when no inspection is active', () async {
      await controller.updateCodeText('__Text__abc', 'hello');
      expect(client.calls,
          ['replaceText:lib/ui/page/feed/feed_page.dart:__Text__abc:hello']);
    });

    test('rewrites .styles.dart to .dart for __Text__ ids', () async {
      await controller.loadInspector('lib/foo/bar_page.dart');
      client.calls.clear();

      await controller.updateCodeText('__Text__hero', 'Hi');

      expect(client.calls,
          ['replaceText:lib/foo/bar_page.dart:__Text__hero:Hi']);
    });

    test('keeps .styles.dart path for non-text ids', () async {
      await controller.loadInspector('lib/foo/bar_page.dart');
      client.calls.clear();

      await controller.updateCodeText('container-1', 'whatever');

      expect(client.calls, [
        'replaceText:lib/foo/bar_page.styles.dart:container-1:whatever',
      ]);
    });
  });

  group('wrap / unwrap / duplicate / insert', () {
    setUp(() async {
      await controller.loadInspector('lib/foo/bar_page.dart');
      client.calls.clear();
    });

    test('wrap no-op when selectedId is null', () async {
      await controller.wrapComponent(null, 'Padding');
      expect(client.calls, isEmpty);
    });

    test('wrap success emits success event', () async {
      final events = await _collectEvents(
        controller,
        () => controller.wrapComponent('c1', 'Padding'),
      );
      expect(client.calls, ['wrap:lib/foo/bar_page.dart:c1:Padding']);
      expect(events.single, isA<CanvasEditorSuccess>());
    });

    test('wrap failure emits error event', () async {
      client.mutationResponse = const InspectorResult.failure('bad');
      final events = await _collectEvents(
        controller,
        () => controller.wrapComponent('c1', 'Padding'),
      );
      expect(events.single, isA<CanvasEditorError>());
    });

    test('unwrap failure emits warning (not error)', () async {
      client.mutationResponse =
          const InspectorResult.failure('nothing to unwrap');
      final events = await _collectEvents(
        controller,
        () => controller.unwrapComponent('c1'),
      );
      expect(events.single, isA<CanvasEditorWarning>());
    });

    test('duplicate failure emits warning', () async {
      client.mutationResponse = const InspectorResult.failure('denied');
      final events = await _collectEvents(
        controller,
        () => controller.duplicateComponent('c1'),
      );
      expect(events.single, isA<CanvasEditorWarning>());
    });

    test('insert success emits success event', () async {
      final events = await _collectEvents(
        controller,
        () => controller.insertComponent('c1'),
      );
      expect(client.calls, ['insert:lib/foo/bar_page.dart:c1']);
      expect(events.single, isA<CanvasEditorSuccess>());
    });
  });
}
