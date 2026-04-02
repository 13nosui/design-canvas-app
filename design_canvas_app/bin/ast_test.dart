import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class TextFinderVisitor extends RecursiveAstVisitor<void> {
  int? targetOffset;
  int? targetLength;
  String? foundText;

  // ASTノードをチェックする共通メソッド
  void checkNode(AstNode node, String name, ArgumentList argList) {
    if (name.contains('Text')) {
      if (argList.arguments.isNotEmpty) {
        final firstArg = argList.arguments.first;
        if (firstArg is SimpleStringLiteral) {
          targetOffset = firstArg.offset;
          targetLength = firstArg.length;
          foundText = firstArg.value;
        }
      }
    }
  }

  // 1. 関数呼び出しとしてパースされた場合 (例: Text('...'))
  @override
  void visitMethodInvocation(MethodInvocation node) {
    checkNode(node, node.methodName.name, node.argumentList);
    super.visitMethodInvocation(node);
  }

  // 2. インスタンス化としてパースされた場合 (例: const Text('...'))
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    checkNode(node, node.constructorName.type.toSource(), node.argumentList);
    super.visitInstanceCreationExpression(node);
  }
}

class TextInspectorVisitor extends RecursiveAstVisitor<void> {
  final String targetId;
  int? targetOffset;
  int? targetLength;
  String? currentFoundText;

  TextInspectorVisitor(this.targetId);

  // ASTノードをチェックする共通メソッド
  void checkNode(AstNode node, String name, ArgumentList argList) {
    if (name.contains('Inspectable')) {
      print(
          '🔍 Found an Inspectable widget (parsed as ${node.runtimeType})...');
      bool isTargetId = false;
      Expression? childExpression;

      for (final arg in argList.arguments) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name;
          final paramValue = arg.expression;

          if (paramName == 'id') {
            print('   ▶ Found id parameter: ${paramValue.toSource()}');
            if (paramValue is SimpleStringLiteral &&
                paramValue.value == targetId) {
              isTargetId = true;
            }
          }
          if (paramName == 'child') {
            childExpression = paramValue;
          }
        }
      }

      if (isTargetId) {
        print('🎯 Matched target ID: "$targetId"');
        if (childExpression != null) {
          // childの中身をTextFinderVisitorで深く探索する
          final textFinder = TextFinderVisitor();
          childExpression.accept(textFinder);

          if (textFinder.targetOffset != null) {
            targetOffset = textFinder.targetOffset;
            targetLength = textFinder.targetLength;
            currentFoundText = textFinder.foundText;
            print('📝 Target Text literal: "$currentFoundText"');
            print('📍 Offset: $targetOffset, Length: $targetLength');
          } else {
            print('⚠️ Could not find a Text widget inside this Inspectable.');
          }
        } else {
          print('⚠️ No child found inside this Inspectable.');
        }
      }
    }
  }

  // 1. 関数呼び出しとしてパースされた場合 (例: Inspectable(...))
  @override
  void visitMethodInvocation(MethodInvocation node) {
    checkNode(node, node.methodName.name, node.argumentList);
    super.visitMethodInvocation(node);
  }

  // 2. インスタンス化としてパースされた場合 (例: const Inspectable(...))
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    checkNode(node, node.constructorName.type.toSource(), node.argumentList);
    super.visitInstanceCreationExpression(node);
  }
}

void main() {
  final filePath = 'lib/ui/page/feed/feed_page.dart';
  final targetId = '__Text__Timeline';

  final file = File(filePath);
  if (!file.existsSync()) {
    print('❌ File not found: $filePath');
    return;
  }

  final sourceCode = file.readAsStringSync();

  print('🌳 Parsing AST...');
  final parseResult =
      parseString(content: sourceCode, throwIfDiagnostics: false);
  final compilationUnit = parseResult.unit;

  final visitor = TextInspectorVisitor(targetId);
  compilationUnit.accept(visitor);

  if (visitor.targetOffset != null && visitor.targetLength != null) {
    final newText = 'Hello AST!';
    final before = sourceCode.substring(0, visitor.targetOffset!);
    final after =
        sourceCode.substring(visitor.targetOffset! + visitor.targetLength!);
    final modifiedCode = "$before'$newText'$after";

    print('\n✅ AST Replacement Demo (Not saving to file):');
    final previewStart =
        (visitor.targetOffset! - 30).clamp(0, sourceCode.length);
    final previewEnd = (visitor.targetOffset! + visitor.targetLength! + 30)
        .clamp(0, sourceCode.length);
    print('--- Before ---');
    print(sourceCode.substring(previewStart, previewEnd));
    print('--- After  ---');
    print(modifiedCode.substring(
        previewStart, previewStart + 60 + newText.length));
  } else {
    print('\n⚠️ Target Inspectable or Text not found.');
  }
}
