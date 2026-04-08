import 'package:flutter_test/flutter_test.dart';
import 'package:design_canvas_app/core/design_system/codegen/page_codegen.dart';

void main() {
  group('slugify', () {
    test('lowercases ASCII', () {
      expect(slugifyForTest('Dashboard'), 'dashboard');
    });

    test('replaces spaces with underscores', () {
      expect(slugifyForTest('user settings'), 'user_settings');
    });

    test('collapses consecutive punctuation into single underscore', () {
      expect(slugifyForTest('user / profile / edit'), 'user_profile_edit');
    });

    test('strips trailing separators', () {
      expect(slugifyForTest('settings...'), 'settings');
    });

    test('strips non-ASCII (Japanese) to fallback', () {
      expect(slugifyForTest('ダッシュボード'), 'x');
    });

    test('mixes ASCII and non-ASCII — keeps the ASCII', () {
      expect(slugifyForTest('ホーム home'), 'home');
    });

    test('preserves digits', () {
      expect(slugifyForTest('screen 2'), 'screen_2');
    });

    test('empty input falls back', () {
      expect(slugifyForTest(''), 'x');
    });
  });

  group('pascalCase', () {
    test('converts space-separated words', () {
      expect(pascalCaseForTest('user settings'), 'UserSettings');
    });

    test('handles single word', () {
      expect(pascalCaseForTest('dashboard'), 'Dashboard');
    });

    test('empty input falls back', () {
      expect(pascalCaseForTest(''), 'X');
    });

    test('non-ASCII falls back', () {
      expect(pascalCaseForTest('ホーム'), 'X');
    });

    test('mixed preserves ASCII parts', () {
      expect(pascalCaseForTest('user プロフィール edit'), 'UserEdit');
    });
  });

  group('generatePageFromScreen', () {
    test('produces .dart + .styles.dart pair with matching names', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Dashboard', 'purpose': 'Overview'},
      );

      expect(page.className, 'Dashboard');
      expect(page.slug, 'dashboard');
      expect(page.dart.path, 'presentation/generated/my_app/dashboard_page.dart');
      expect(
        page.styles.path,
        'presentation/generated/my_app/dashboard_page.styles.dart',
      );
    });

    test('generated .dart references the matching styles file', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'Landing screen'},
      );

      expect(page.dart.content, contains("import 'home_page.styles.dart';"));
      expect(page.dart.content, contains('class HomePage extends StatelessWidget'));
      expect(page.dart.content, contains('HomePageStyles.backgroundColor'));
      expect(page.dart.content, contains("'Home'"));
      expect(page.dart.content, contains("'Landing screen'"));
    });

    test('generated styles references AppTokens per ADR-0005', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
      );

      expect(
        page.styles.content,
        contains("import '../../../core/design_system/tokens.dart';"),
      );
      expect(page.styles.content, contains('class HomePageStyles'));
      expect(page.styles.content, contains('AppTokens.colorTextPrimary'));
      expect(page.styles.content, contains('AppTokens.spaceL'));
      // Unmapped raw values are marked as token candidates.
      expect(page.styles.content, contains('// TODO: New Token Candidate'));
    });

    test('escapes single quotes inside screen name and purpose', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {
          'name': "Alice's home",
          'purpose': "It's where tasks live",
        },
      );

      expect(page.dart.content, contains(r"'Alice\'s home'"));
      expect(page.dart.content, contains(r"'It\'s where tasks live'"));
    });

    test('falls back when name is empty', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': '', 'purpose': 'no name'},
        fallbackIndex: 3,
      );

      expect(page.slug, 'screen_3');
      expect(page.className, 'Screen3');
    });

    test('falls back when name is all non-ASCII', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'ダッシュボード', 'purpose': 'JP'},
        fallbackIndex: 1,
      );

      expect(page.slug, 'screen_1');
      expect(page.className, 'Screen1');
      // The Japanese name still appears as a display string literal.
      expect(page.dart.content, contains('ダッシュボード'));
    });
  });

  group('generatePagesFromPayload', () {
    test('returns empty list for malformed payload', () {
      expect(generatePagesFromPayload({}), isEmpty);
      expect(generatePagesFromPayload({'detail': 'not a map'}), isEmpty);
      expect(
        generatePagesFromPayload({'detail': {'screens': 'not a list'}}),
        isEmpty,
      );
    });

    test('generates one page pair per screen', () {
      final payload = {
        'title': 'Task Manager',
        'detail': {
          'screens': [
            {'name': 'Dashboard', 'purpose': 'overview'},
            {'name': 'Settings', 'purpose': 'prefs'},
            {'name': 'Profile', 'purpose': 'user info'},
          ],
        },
      };

      final pages = generatePagesFromPayload(payload);
      expect(pages, hasLength(3));
      expect(pages.map((p) => p.slug), ['dashboard', 'settings', 'profile']);

      for (final p in pages) {
        expect(
          p.dart.path,
          startsWith('presentation/generated/task_manager/'),
        );
      }
    });

    test('uses fallback project slug when title is non-ASCII', () {
      final payload = {
        'title': 'タスク管理',
        'detail': {
          'screens': [
            {'name': 'Home', 'purpose': 'x'},
          ],
        },
      };

      final pages = generatePagesFromPayload(payload);
      expect(pages, hasLength(1));
      expect(pages.first.dart.path, startsWith('presentation/generated/imported/'));
    });
  });
}
