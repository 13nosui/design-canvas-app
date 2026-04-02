import 'dart:convert';
import 'dart:io';
import 'dart:async'; // 💡 Timerを使うために追加

const int port = 8080;
Timer? _reloadTimer; // 💡 連続発火を防ぐためのタイマー

void setCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
  response.headers.add('Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept');
}

// --- Hot Reload を安全に遅延発火させる ---
void triggerHotReload() {
  // 💡 連続でリクエストが来ても、前のタイマーをキャンセルして最後の1回だけ実行する（Debounce）
  if (_reloadTimer?.isActive ?? false) _reloadTimer!.cancel();

  _reloadTimer = Timer(const Duration(milliseconds: 250), () {
    print('🔥 Triggering Auto Hot-Reload safely...');

    // 💡 "flutter"という大雑把な指定をやめ、ターミナルのメインプロセス（flutter_tools）だけを正確に狙撃する
    Process.run('pkill', ['-USR1', '-f', 'flutter_tools.snapshot'])
        .then((result) {
      if (result.exitCode == 0) {
        print('✅ Safely sent Hot Reload signal!');
      } else {
        // 環境によってプロセス名が違う場合のフォールバック
        Process.run('pkill', ['-USR1', '-f', 'flutter run']);
        print('✅ Safely sent Hot Reload signal! (Fallback)');
      }
    });
  });
}

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('🚀 Local Git Server is running on port $port');
  print('Waiting for design canvas commits...');
  print(
      '💡 Tip: No WebSocket URL needed anymore! Just edit and watch the magic.');

  await for (HttpRequest request in server) {
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

        print('📝 Received commit request: $message');

        print('  > git add .');
        final addResult = await Process.run('git', ['add', '.']);
        if (addResult.exitCode != 0)
          throw Exception('git add failed: ${addResult.stderr}');

        print('  > git commit -m "$message"');
        final commitResult =
            await Process.run('git', ['commit', '-m', message]);
        if (commitResult.exitCode != 0 &&
            !commitResult.stdout.toString().contains('nothing to commit')) {
          throw Exception(
              'git commit failed: ${commitResult.stderr}\n${commitResult.stdout}');
        }

        print('  > git push origin main');
        final pushResult = await Process.run('git', ['push', 'origin', 'main']);
        if (pushResult.exitCode != 0)
          throw Exception('git push failed: ${pushResult.stderr}');

        print('✅ Successfully pushed to main!');
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'success'}));
      } catch (e) {
        print('❌ Error during git operation: $e');
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
        var result =
            await Process.run('cursor', ['-g', filePath], runInShell: true);
        if (result.exitCode != 0) {
          result =
              await Process.run('code', ['-g', filePath], runInShell: true);
        }
        if (result.exitCode != 0)
          throw Exception('Failed to open IDE: ${result.stderr}');
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'success'}));
      } catch (e) {
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
            final value =
                match.group(3)!.trim().replaceAll(RegExp(r'\s+'), ' ');
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
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        final filePath = data['path'];
        final className = data['className'];
        final fieldName = data['name'];
        final newValue = data['value'];

        final file = File(filePath);
        String fileContent = file.readAsStringSync();

        if (className != null) {
          final classRegex =
              RegExp(r'(class\s+' + className + r'\s*\{)([^}]*)(\})');
          if (classRegex.hasMatch(fileContent)) {
            bool matchedProperty = false;
            fileContent =
                fileContent.replaceFirstMapped(classRegex, (classMatch) {
              final prefix = classMatch.group(1)!;
              String body = classMatch.group(2)!;
              final suffix = classMatch.group(3)!;
              final replaceRegex = RegExp(
                  r'(static\s+(?:const|final)(?:\s+[\w<>, ]+\??)?\s+' +
                      fieldName +
                      r'\s*=\s*)([^;]+)(;)');
              if (replaceRegex.hasMatch(body)) {
                body = body.replaceFirstMapped(
                    replaceRegex, (m) => '${m.group(1)}$newValue${m.group(3)}');
                matchedProperty = true;
              }
              return '$prefix$body$suffix';
            });
            file.writeAsStringSync(fileContent);
            if (matchedProperty) {
              print(
                  '[SUCCESS] Updated style property: $className.$fieldName = $newValue');
              triggerHotReload();
            }
          }
        } else {
          final replaceRegex = RegExp(
              r'(static\s+(?:const|final)(?:\s+[\w<>, ]+\??)?\s+' +
                  fieldName +
                  r'\s*=\s*)([^;]+)(;)');
          if (replaceRegex.hasMatch(fileContent)) {
            fileContent = fileContent.replaceFirstMapped(
                replaceRegex, (m) => '${m.group(1)}$newValue${m.group(3)}');
            file.writeAsStringSync(fileContent);
            print(
                '[SUCCESS] Updated global style property: $fieldName = $newValue');
            triggerHotReload();
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
      try {
        final content = await utf8.decoder.bind(request).join();
        final data = jsonDecode(content);
        final filePath = data['path'];
        final className = data['className'];
        final fieldName = data['name'];
        final tokenName = data['tokenName'];
        final tokenValue = data['value'];

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
                body = body.replaceFirstMapped(replaceRegex,
                    (m) => '${m.group(1)}AppTokens.$tokenName;\n');
              }
              return '$prefix$body$suffix';
            });
            styleFile.writeAsStringSync(styleContent);
            triggerHotReload();
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

        final replaceRegex = RegExp(
            r"(id:\s*'" + id + r"'[\s\S]*?)(?:const\s+)?(Text\(\s*')([^']+)'");
        if (replaceRegex.hasMatch(fileContent)) {
          fileContent = fileContent.replaceFirstMapped(
              replaceRegex, (m) => '${m.group(1)}${m.group(2)}$newText\'');
          file.writeAsStringSync(fileContent);
          print('[SUCCESS] Replaced text in $filePath for id=$id');
          triggerHotReload();

          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({'status': 'success'}));
        } else {
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
                content = content.replaceFirstMapped(replaceRegex,
                    (m) => '${m.group(1)}${m.group(2)}$newText\'');
                file.writeAsStringSync(content);
                print(
                    '[SUCCESS] Replaced text in ${file.path} for id=$id (Fallback Global Search)');
                triggerHotReload();

                request.response.statusCode = HttpStatus.ok;
                request.response.write(
                    jsonEncode({'status': 'success', 'foundIn': file.path}));
                found = true;
                break;
              }
            }
          }
          if (!found) {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write(jsonEncode({'error': 'Target not found'}));
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
