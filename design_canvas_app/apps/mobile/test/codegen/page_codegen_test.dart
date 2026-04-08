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

  group('rich page generation', () {
    test('omits meta/api/stack sections when not provided', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'Landing'},
      );

      expect(page.dart.content, isNot(contains('関連 API')));
      expect(page.dart.content, isNot(contains('使用スタック')));
      expect(page.dart.content, isNot(contains('Wrap(')));
    });

    test('emits per-screen sections cards from screen.sections', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {
          'name': 'Dashboard',
          'purpose': 'Overview',
          'sections': [
            {'label': 'アクション', 'body': 'タスクを追加できる'},
            {'label': '表示情報', 'body': '今日のタスク一覧'},
          ],
        },
      );

      expect(page.dart.content, contains("'この画面について'"));
      expect(page.dart.content, contains("'アクション'"));
      expect(page.dart.content, contains("'タスクを追加できる'"));
      expect(page.dart.content, contains("'表示情報'"));
      expect(page.dart.content, contains("'今日のタスク一覧'"));
      expect(page.dart.content, contains('DashboardPageStyles.sectionCardDecoration'));
      expect(page.dart.content, contains('DashboardPageStyles.sectionCardLabelStyle'));
    });

    test('escapes single quotes in screen sections', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {
          'name': 'Home',
          'purpose': 'x',
          'sections': [
            {'label': "Alice's note", 'body': "Bob's data shows up"},
          ],
        },
      );

      expect(page.dart.content, contains(r"'Alice\'s note'"));
      expect(page.dart.content, contains(r"'Bob\'s data shows up'"));
    });

    test('screen without sections omits the section header', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
      );

      expect(page.dart.content, isNot(contains("'この画面について'")));
    });

    test('styles file includes sectionCard tokens', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
      );

      expect(page.styles.content, contains('sectionCardDecoration'));
      expect(page.styles.content, contains('sectionCardLabelStyle'));
    });

    test('emits meta badges Wrap with status colors', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
        meta: [
          {'label': '優先度高', 'color': 'green'},
          {'label': '0.3ms', 'color': 'blue'},
        ],
      );

      expect(page.dart.content, contains('Wrap('));
      expect(page.dart.content, contains("'優先度高'"));
      expect(page.dart.content, contains("'0.3ms'"));
      expect(page.dart.content, contains('HomePageStyles.statusBgGreen'));
      expect(page.dart.content, contains('HomePageStyles.statusFgBlue'));
    });

    test('emits API section with card per entry', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
        apis: [
          {'name': 'GET /tasks', 'description': 'Fetch today tasks'},
          {'name': 'POST /tasks', 'description': 'Create a task'},
        ],
      );

      expect(page.dart.content, contains("'関連 API'"));
      expect(page.dart.content, contains("'GET /tasks'"));
      expect(page.dart.content, contains("'Fetch today tasks'"));
      expect(page.dart.content, contains("'POST /tasks'"));
      expect(page.dart.content, contains('HomePageStyles.cardDecoration'));
      expect(page.dart.content, contains('HomePageStyles.apiCodeStyle'));
    });

    test('emits stack chips', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
        stack: ['Next.js', 'Supabase', 'Stripe'],
      );

      expect(page.dart.content, contains("'使用スタック'"));
      expect(page.dart.content, contains("'Next.js'"));
      expect(page.dart.content, contains("'Supabase'"));
      expect(page.dart.content, contains("'Stripe'"));
      expect(page.dart.content, contains('HomePageStyles.chipBackground'));
    });

    test('emits AppBar row with icon when provided', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
        projectTitle: 'Task Manager',
        icon: '🎯',
      );

      expect(page.dart.content, contains("'🎯'"));
      expect(page.dart.content, contains("'Task Manager'"));
      expect(page.dart.content, contains('Row('));
    });

    test('styles file includes all new tokens', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
      );

      // New style constants exist regardless of whether sections are used.
      expect(page.styles.content, contains('statusBgGreen'));
      expect(page.styles.content, contains('statusFgSlate'));
      expect(page.styles.content, contains('cardDecoration'));
      expect(page.styles.content, contains('apiCodeStyle'));
      expect(page.styles.content, contains('chipBackground'));
      expect(page.styles.content, contains('sectionLabelStyle'));
      expect(page.styles.content, contains('sectionGap'));
    });

    test('escapes single quotes in API and stack entries', () {
      final page = generatePageFromScreen(
        projectSlug: 'my_app',
        screen: {'name': 'Home', 'purpose': 'x'},
        apis: [
          {'name': "GET /it's", 'description': "User's data"},
        ],
        stack: ["Alice's SDK"],
      );

      expect(page.dart.content, contains(r"'GET /it\'s'"));
      expect(page.dart.content, contains(r"'User\'s data'"));
      expect(page.dart.content, contains(r"'Alice\'s SDK'"));
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

    test('propagates project-level context into every generated page', () {
      final payload = {
        'title': 'Task Manager',
        'icon': '🎯',
        'meta': [
          {'label': '優先度高', 'color': 'green'},
        ],
        'detail': {
          'screens': [
            {'name': 'Dashboard', 'purpose': 'overview'},
            {'name': 'Settings', 'purpose': 'prefs'},
          ],
          'apis': [
            {'name': 'GET /tasks', 'description': 'Fetch tasks'},
          ],
          'stack': ['Next.js', 'Supabase'],
        },
      };

      final pages = generatePagesFromPayload(payload);
      expect(pages, hasLength(2));
      for (final p in pages) {
        expect(p.dart.content, contains("'🎯'"));
        expect(p.dart.content, contains("'Task Manager'"));
        expect(p.dart.content, contains("'優先度高'"));
        expect(p.dart.content, contains("'GET /tasks'"));
        expect(p.dart.content, contains("'Next.js'"));
        expect(p.dart.content, contains("'Supabase'"));
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
