import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class RouteVisitor extends RecursiveAstVisitor<void> {
  final List<Map<String, dynamic>> routes = [];
  String? parentPath;

  RouteVisitor([this.parentPath]);

  void _processNode(String nodeName, ArgumentList argumentList) {
    if (nodeName == 'GoRoute') {
      String? path;
      String? name;
      String? builderClassName;
      List<Map<String, dynamic>> children = [];

      for (var arg in argumentList.arguments) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name;
          if (paramName == 'path') {
            final val = arg.expression;
            if (val is SimpleStringLiteral) {
              path = val.value;
            }
          } else if (paramName == 'name') {
            final val = arg.expression;
            if (val is SimpleStringLiteral) {
              name = val.value;
            }
          } else if (paramName == 'builder') {
            final val = arg.expression;
            if (val is FunctionExpression) {
              final body = val.body;
              if (body is ExpressionFunctionBody) {
                final ret = body.expression;
                if (ret is InstanceCreationExpression) {
                  builderClassName = ret.constructorName.type.name2.lexeme;
                } else if (ret is MethodInvocation) {
                  builderClassName = ret.methodName.name;
                }
              }
            }
          } else if (paramName == 'routes') {
            final val = arg.expression;
            if (val is ListLiteral) {
              for (var elem in val.elements) {
                final childVisitor = RouteVisitor(path);
                elem.accept(childVisitor);
                children.addAll(childVisitor.routes);
              }
            }
          }
        }
      }

      if (path != null) {
        String fullPath = path;
        if (parentPath != null && !path.startsWith('/')) {
          fullPath = '\$parentPath/\$path'.replaceAll('//', '/');
        }
        
        name ??= fullPath;
        
        routes.add({
          'path': fullPath,
          'name': name,
          'builder': builderClassName ?? 'Container',
          'children': children,
        });
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _processNode(node.methodName.name, node.argumentList);
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _processNode(node.constructorName.type.name2.lexeme, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }
}

void processRoutes(List<Map<String, dynamic>> routes, Map<String, dynamic> flatRoutes, [String? parentName]) {
  for (var route in routes) {
    final name = route['name'] as String;
    final children = route['children'] as List<Map<String, dynamic>>;
    
    final childNames = children.map((c) => c['name'] as String).toList();
    
    flatRoutes[name] = {
      'path': route['path'],
      'name': name,
      'builder': route['builder'],
      'children': childNames,
    };
    
    processRoutes(children, flatRoutes, name);
  }
}

void main() {
  final file = File('lib/app/router.dart');
  if (!file.existsSync()) {
    print('router.dart not found.');
    return;
  }

  final content = file.readAsStringSync();
  final result = parseString(content: content);

  final visitor = RouteVisitor();
  result.unit.accept(visitor);

  final flatRoutes = <String, dynamic>{};
  processRoutes(visitor.routes, flatRoutes);

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln("import 'package:flutter/material.dart';");
  buffer.writeln("import '../../presentation/pages/home_page.dart';");
  buffer.writeln("import '../../presentation/pages/login_page.dart';");
  buffer.writeln("import '../../presentation/pages/settings_page.dart';");
  buffer.writeln();
  buffer.writeln('class CanvasRoute {');
  buffer.writeln('  final String name;');
  buffer.writeln('  final String path;');
  buffer.writeln('  final WidgetBuilder builder;');
  buffer.writeln('  final List<String> childrenNames;');
  buffer.writeln('  const CanvasRoute({required this.name, required this.path, required this.builder, required this.childrenNames});');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('final Map<String, CanvasRoute> generatedRoutes = {');
  
  for (final name in flatRoutes.keys) {
    final r = flatRoutes[name]!;
    final safeName = name.replaceAll("'", "\\'");
    final safePath = r['path'].replaceAll("'", "\\'");
    final builder = r['builder'];
    final children = (r['children'] as List<String>).map((c) => "'$c'").join(', ');
    buffer.writeln("  '$safeName': CanvasRoute(");
    buffer.writeln("    name: '$safeName',");
    buffer.writeln("    path: '$safePath',");
    buffer.writeln("    builder: (context) => const $builder(),");
    buffer.writeln("    childrenNames: const [$children],");
    buffer.writeln("  ),");
  }
  buffer.writeln('};');

  final outputDir = Directory('lib/core/navigation');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outFile = File('lib/core/navigation/sitemap.g.dart');
  outFile.writeAsStringSync(buffer.toString());
  print('Generated \${outFile.path} successfully.');
}
