// CanvasInspectorPanel — extracted from `design_canvas_page.dart` to
// shrink that file and make the inspector independently reviewable /
// testable. Pure UI: takes the inspector state + callbacks as params.
//
// Parent (the canvas state) still owns _inspectedFields, _selectedComponentId,
// etc. and the AST-write callbacks. This widget only renders and forwards.

import 'package:flutter/material.dart';

import 'property_field_editor.dart';

class CanvasInspectorPanel extends StatelessWidget {
  const CanvasInspectorPanel({
    super.key,
    required this.inspectedFilePath,
    required this.inspectedFields,
    required this.isLoading,
    required this.selectedComponentId,
    required this.onUpdateStyleField,
    required this.onPromoteToken,
  });

  final String? inspectedFilePath;
  final List<dynamic> inspectedFields;
  final bool isLoading;
  final String? selectedComponentId;

  /// Called when the user edits a property value. Matches the signature
  /// of the legacy `_updateStyleField(className, name, newVal)`.
  final Future<void> Function(
          String? className, String name, String newValue)
      onUpdateStyleField;

  /// Called when the user clicks "Promote to <tokenName>". Matches
  /// the legacy `_promoteToken(className, name, tokenName, valueStr)`.
  /// tokenName can be null; the UI only renders the promote button when
  /// it is non-null, but the underlying callback accepts null for safety.
  final Future<void> Function(
          String? className, String name, String? tokenName, String value)
      onPromoteToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨ Component Inspector',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Target: ${inspectedFilePath?.split('/').last ?? '(none)'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!isLoading) ..._buildFieldList(context),
      ],
    );
  }

  List<Widget> _buildFieldList(BuildContext context) {
    final filteredFields = inspectedFields.where((f) {
      if (selectedComponentId == null) return true;
      return (f as Map)['className'] == selectedComponentId;
    }).toList();

    if (filteredFields.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(20),
          child: Text('No styling tokens found in this component.'),
        ),
      ];
    }

    return filteredFields.map<Widget>((field) {
      final f = field as Map;
      final className = f['className'] as String?;
      final isAppToken = f['isAppToken'] == true;
      final isCandidate = f['isCandidate'] == true;
      final name = f['name'] as String;
      final valueStr = f['value'] as String;
      final candidateName = f['candidateName'] as String?;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedComponentId == null && className != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  className,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: PropertyFieldEditor(
                    label: name,
                    initialValue: valueStr,
                    isAppToken: isAppToken,
                    onSubmit: (newVal) =>
                        onUpdateStyleField(className, name, newVal),
                  ),
                ),
                if (isAppToken)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.link,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            if (isCandidate && candidateName != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 24,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upgrade, size: 12),
                  label: Text('Promote to $candidateName',
                      style: const TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () =>
                      onPromoteToken(className, name, candidateName, valueStr),
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }
}
