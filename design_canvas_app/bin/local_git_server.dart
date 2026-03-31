import 'dart:convert';
import 'dart:io';

const int port = 8080;

void setCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.headers.add('Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept');
}

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('🚀 Local Git Server is running on port \$port');
  print('Waiting for design canvas commits...');

  await for (HttpRequest request in server) {
    print('Received request: ${request.method} ${request.uri.path}');
    setCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/commit') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final message = data['message'] as String?;

        if (message == null || message.isEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response
              .write(jsonEncode({'error': 'Message cannot be empty'}));
          await request.response.close();
          continue;
        }

        print('📝 Received commit request: \$message');

        // 1. git add .
        print('  > git add .');
        final addResult = await Process.run('git', ['add', '.']);
        if (addResult.exitCode != 0) {
          throw Exception('git add failed: \${addResult.stderr}');
        }

        // 2. git commit -m "{message}"
        print('  > git commit -m "\$message"');
        final commitResult =
            await Process.run('git', ['commit', '-m', message]);
        // コミットするものが無い場合も考慮 (exit Code 1)
        if (commitResult.exitCode != 0 &&
            !commitResult.stdout.toString().contains('nothing to commit')) {
          throw Exception(
              'git commit failed: \${commitResult.stderr}\\n\${commitResult.stdout}');
        }

        // 3. git push origin main
        print('  > git push origin main');
        final pushResult = await Process.run('git', ['push', 'origin', 'main']);
        if (pushResult.exitCode != 0) {
          throw Exception('git push failed: \${pushResult.stderr}');
        }

        print('✅ Successfully pushed to main!');
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'success'}));
      } catch (e) {
        print('❌ Error during git operation: \$e');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
      } finally {
        await request.response.close();
      }
    } else if (request.method == 'POST' && request.uri.path == '/open-ide') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final filePath = data['filePath'] as String?;

        if (filePath == null || filePath.isEmpty) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response
              .write(jsonEncode({'error': 'filePath cannot be empty'}));
          await request.response.close();
          continue;
        }

        print('💻 Opening IDE for: $filePath');

        // Try cursor first, then fallback to code
        var result =
            await Process.run('cursor', ['-g', filePath], runInShell: true);
        if (result.exitCode != 0) {
          print('Cursor not found, falling back to VS Code...');
          result =
              await Process.run('code', ['-g', filePath], runInShell: true);
        }

        if (result.exitCode != 0) {
          throw Exception('Failed to open IDE: ${result.stderr}');
        }

        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'success'}));
      } catch (e) {
        print('❌ Error opening IDE: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
      } finally {
        await request.response.close();
      }
    } else if (request.method == 'GET' &&
        request.uri.path == '/inspector/parse') {
      try {
        final filePath = request.uri.queryParameters['path'];
        if (filePath == null) throw Exception('path is required');
        final file = File(filePath);
        if (!file.existsSync()) throw Exception('File not found');

        final content = await file.readAsString();
        final List<Map<String, dynamic>> fields = [];

        // クラス単位でブロックを抽出し、その中の定数をパースする
        final classRegex = RegExp(r'class\s+([a-zA-Z0-9_]+)\s*\{([^}]*)\}');
        final classMatches = classRegex.allMatches(content);

        for (final classMatch in classMatches) {
          final className = classMatch.group(1)!;
          final classBody = classMatch.group(2)!;

          final regex = RegExp(
              r'static\s+(const|final)\s+([a-zA-Z0-9_]+)\s*=\s*([^;]+);([^\n]*)');
          final matches = regex.allMatches(classBody);

          for (final match in matches) {
            final name = match.group(2)!;
            final value = match
                .group(3)!
                .trim()
                .replaceAll(RegExp(r'\s+'), ' '); // flatten multiline
            final comment = match.group(4) ?? '';

            final isCandidate = comment.contains('TODO: New Token Candidate');
            String? candidateName;
            if (isCandidate) {
              final candMatch =
                  RegExp(r'-\s*([a-zA-Z0-9_]+)').firstMatch(comment);
              if (candMatch != null) candidateName = candMatch.group(1);
            }

            fields.add({
              'className': className,
              'name': name,
              'value': value,
              'isAppToken': value.contains('AppTokens.'),
              'isCandidate': isCandidate,
              'candidateName': candidateName,
            });
          }
        }

        request.response.statusCode = HttpStatus.ok;
        request.response
            .write(jsonEncode({'status': 'success', 'fields': fields}));
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
      } finally {
        await request.response.close();
      }
    } else if (request.method == 'POST' &&
        request.uri.path == '/inspector/update') {
      // リアルタイムプレビュー用：ドラッグ等による書き換え
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        final filePath = data['path'];
        final className = data['className'];
        final fieldName = data['name'];
        final newValue = data['value']; // "AppTokens.xxx" or "Color(0xFF...)"

        final file = File(filePath);
        String fileContent = file.readAsStringSync();

        // クラスブロック単位で置換処理を行う
        if (className != null) {
          final classRegex =
              RegExp(r'(class\s+' + className + r'\s*\{)([^}]*)(\})');
          if (classRegex.hasMatch(fileContent)) {
            fileContent =
                fileContent.replaceFirstMapped(classRegex, (classMatch) {
              final prefix = classMatch.group(1)!;
              String body = classMatch.group(2)!;
              final suffix = classMatch.group(3)!;

              final replaceRegex = RegExp(r'(static\s+(?:const|final)\s+' +
                  fieldName +
                  r'\s*=\s*)([^;]+)(;)');
              if (replaceRegex.hasMatch(body)) {
                body = body.replaceFirstMapped(replaceRegex, (m) {
                  return '${m.group(1)}$newValue${m.group(3)}';
                });
              }
              return '$prefix$body$suffix';
            });
            file.writeAsStringSync(fileContent);
          }
        } else {
          // Fallback for non-class styles
          final replaceRegex = RegExp(r'(static\s+(?:const|final)\s+' +
              fieldName +
              r'\s*=\s*)([^;]+)(;)');
          if (replaceRegex.hasMatch(fileContent)) {
            fileContent = fileContent.replaceFirstMapped(replaceRegex, (m) {
              return '${m.group(1)}$newValue${m.group(3)}';
            });
            file.writeAsStringSync(fileContent);
          }
        }

        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'success'}));
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
      } finally {
        await request.response.close();
      }
    } else if (request.method == 'POST' &&
        request.uri.path == '/inspector/promote') {
      // Token候補を公式トークンに昇格させる
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        final filePath = data['path'];
        final className = data['className'];
        final fieldName = data['name'];
        final tokenName = data['tokenName'];
        final tokenValue = data['value'];

        // 1. tokens.dart に追記する
        final tokenFile = File('lib/core/design_system/tokens.dart');
        String tokenContent = tokenFile.readAsStringSync();
        final appendIndex = tokenContent.lastIndexOf('}');
        if (appendIndex != -1) {
          final insertText =
              '\n  static const $tokenName = $tokenValue; // promoted from $fieldName\n';
          tokenContent = tokenContent.substring(0, appendIndex) +
              insertText +
              tokenContent.substring(appendIndex);
          tokenFile.writeAsStringSync(tokenContent);
        }

        // 2. 対象スタイルファイルのフィールドを AppTokens.xxx に置換、TODOコメントを削除
        final styleFile = File(filePath);
        String styleContent = styleFile.readAsStringSync();

        if (className != null) {
          final classRegex =
              RegExp(r'(class\s+' + className + r'\s*\{)([^}]*)(\})');
          if (classRegex.hasMatch(styleContent)) {
            styleContent =
                styleContent.replaceFirstMapped(classRegex, (classMatch) {
              final prefix = classMatch.group(1)!;
              String body = classMatch.group(2)!;
              final suffix = classMatch.group(3)!;

              final replaceRegex = RegExp(r'(static\s+(?:const|final)\s+' +
                  fieldName +
                  r'\s*=\s*)([^;]+)(;[^\n]*\n?)');
              if (replaceRegex.hasMatch(body)) {
                body = body.replaceFirstMapped(replaceRegex, (m) {
                  return '${m.group(1)}AppTokens.$tokenName;\n'; // NOTE: Comment removed
                });
              }
              return '$prefix$body$suffix';
            });
            styleFile.writeAsStringSync(styleContent);
          }
        } else {
          final replaceRegex = RegExp(r'(static\s+(?:const|final)\s+' +
              fieldName +
              r'\s*=\s*)([^;]+)(;[^\n]*\n?)');
          if (replaceRegex.hasMatch(styleContent)) {
            styleContent = styleContent.replaceFirstMapped(replaceRegex, (m) {
              return '${m.group(1)}AppTokens.$tokenName;\n'; // NOTE: Comment removed
            });
            styleFile.writeAsStringSync(styleContent);
          }
        }

        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'success'}));
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
      } finally {
        await request.response.close();
      }
    } else if (request.method == 'POST' &&
        request.uri.path.contains('/inspector/replace_text')) {
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        final filePath = data['path'];
        final id = data['id'];
        final newText = data['text'];

        final file = File(filePath);
        String fileContent = file.readAsStringSync();

        // 対象のInspectable(id: '__Text__Timeline')の内部にある Text('...') の文字列を置換する
        // 間に他のWidget（ContainerやPadding等）がいくら挟まっていてもマッチできるよう [\s\S]*? を使用
        // constがあってもなくてもマッチし、置換時にconstを剥がす
        final replaceRegex = RegExp(
            r"(id:\s*'" + id + r"'[\s\S]*?)(?:const\s+)?(Text\(\s*')([^']+)'");
        if (replaceRegex.hasMatch(fileContent)) {
          fileContent = fileContent.replaceFirstMapped(replaceRegex, (m) {
            return '${m.group(1)}${m.group(2)}$newText\'';
          });
          file.writeAsStringSync(fileContent);

          print('[SUCCESS] Replaced text in $filePath for id=$id');

          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({'status': 'success'}));
        } else {
          print(
              '[WARNING] /inspector/replace_text: Target text not found in $filePath. Starting global fallback search in lib/ui/ ...');

          bool found = false;
          final uiDir = Directory('lib/ui');
          if (uiDir.existsSync()) {
            final dartFiles = uiDir
                .listSync(recursive: true)
                .where((f) => f is File && f.path.endsWith('.dart'));
            for (final f in dartFiles) {
              final file = f as File;
              String content = file.readAsStringSync();
              if (replaceRegex.hasMatch(content)) {
                content = content.replaceFirstMapped(replaceRegex, (m) {
                  return '${m.group(1)}${m.group(2)}$newText\'';
                });
                file.writeAsStringSync(content);
                print(
                    '[SUCCESS] Replaced text in ${file.path} for id=$id (Fallback Global Search)');

                request.response.statusCode = HttpStatus.ok;
                request.response.write(
                    jsonEncode({'status': 'success', 'foundIn': file.path}));
                found = true;
                break;
              }
            }
          }

          if (!found) {
            print(
                '[ERROR] /inspector/replace_text: Regex did not match any text element for id=$id in any lib/ui/ files either.');
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({
              'error':
                  'Regex did not match any text element for id $id even after global search'
            }));
          }
        }
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
      } finally {
        await request.response.close();
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode({'error': 'Not Found'}));
      await request.response.close();
    }
  }
}
