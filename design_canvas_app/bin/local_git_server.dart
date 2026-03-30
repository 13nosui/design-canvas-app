import 'dart:convert';
import 'dart:io';

const int port = 8080;

void setCorsHeaders(HttpResponse response) {
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.headers.add('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
}

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('🚀 Local Git Server is running on port \$port');
  print('Waiting for design canvas commits...');

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
          request.response.write(jsonEncode({'error': 'Message cannot be empty'}));
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
        final commitResult = await Process.run('git', ['commit', '-m', message]);
        // コミットするものが無い場合も考慮 (exit Code 1)
        if (commitResult.exitCode != 0 && !commitResult.stdout.toString().contains('nothing to commit')) {
          throw Exception('git commit failed: \${commitResult.stderr}\\n\${commitResult.stdout}');
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
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode({'error': 'Not Found'}));
      await request.response.close();
    }
  }
}
