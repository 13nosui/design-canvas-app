// CanvasLiveEditorPanel — the right-hand "Figma-like" live style editor.
// Extracted from `design_canvas_page.dart` as the biggest chunk of that
// file (originally ~590 lines).
//
// Contents:
//   - Optional component inspector (CanvasInspectorPanel) at the top
//   - Lint mode / background decor / UI state toggles
//   - Color / layout / effect / typography token editors
//   - Export + Commit buttons
//
// Parent still owns the State. This widget is pure UI and forwards
// mutation intent via callbacks.

import 'package:flutter/material.dart';

import '../../core/design_system/theme_controller.dart';
import 'canvas_commit_dialog.dart';
import 'canvas_inspector_panel.dart';
import 'property_field_editor.dart';

class CanvasLiveEditorPanel extends StatelessWidget {
  const CanvasLiveEditorPanel({
    super.key,
    required this.inspectorFilePath,
    required this.inspectorFields,
    required this.inspectorIsLoading,
    required this.selectedComponentId,
    required this.onUpdateStyleField,
    required this.onPromoteToken,
    required this.onExportAndSaveCode,
  });

  // Inspector sub-panel parameters.
  final String? inspectorFilePath;
  final List<dynamic> inspectorFields;
  final bool inspectorIsLoading;
  final String? selectedComponentId;
  final Future<void> Function(
          String? className, String name, String newValue)
      onUpdateStyleField;
  final Future<void> Function(
          String? className, String name, String? tokenName, String value)
      onPromoteToken;

  // Export (owned by canvas state, needs context + themeController).
  final void Function(BuildContext context, ThemeControllerProvider tc)
      onExportAndSaveCode;

  static const List<Color> _paletteColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeControllerProvider.of(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inspectorFilePath != null)
                CanvasInspectorPanel(
                  inspectedFilePath: inspectorFilePath,
                  inspectedFields: inspectorFields,
                  isLoading: inspectorIsLoading,
                  selectedComponentId: selectedComponentId,
                  onUpdateStyleField: onUpdateStyleField,
                  onPromoteToken: onPromoteToken,
                ),
              if (inspectorFilePath != null) const Divider(thickness: 4),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Live Style Editor',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🚨 Visual Lint Mode',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Switch(
                      value: themeController.isLintMode,
                      activeColor: Colors.redAccent,
                      onChanged: (val) {
                        themeController.updateTheme(isLintMode: val);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('🎭 UI State',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    SegmentedButton<MockUIState>(
                      segments: const [
                        ButtonSegment(
                            value: MockUIState.normal,
                            label:
                                Text('Normal', style: TextStyle(fontSize: 11))),
                        ButtonSegment(
                            value: MockUIState.loading,
                            label: Text('Loading',
                                style: TextStyle(fontSize: 11))),
                        ButtonSegment(
                            value: MockUIState.empty,
                            label:
                                Text('Empty', style: TextStyle(fontSize: 11))),
                        ButtonSegment(
                            value: MockUIState.error,
                            label:
                                Text('Error', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {themeController.currentMockState},
                      onSelectionChanged: (Set<MockUIState> newSelection) {
                        themeController.updateTheme(
                            mockState: newSelection.first);
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                child: const Text('GLOBAL APP TOKENS',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2)),
              ),
              // --- Colors ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PropertyFieldEditor(
                      label: 'Primary Color',
                      initialValue:
                          'Color(0x${themeController.primaryColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()})',
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'Color\(0x([a-fA-F0-9]{8})\)')
                            .firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              primary:
                                  Color(int.parse(match.group(1)!, radix: 16)));
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _paletteColors.map((color) {
                        final isSelected =
                            themeController.primaryColor.value == color.value;
                        return GestureDetector(
                          onTap: () =>
                              themeController.updateTheme(primary: color),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.black12,
                                  width: isSelected ? 2 : 1),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // --- Layout & Spacing ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    PropertyFieldEditor(
                      label: 'Spacing Base',
                      initialValue:
                          themeController.spacingBase.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              spacing: double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Border Radius',
                      initialValue:
                          themeController.borderRadius.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              radius: double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // --- Effects & Borders ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    PropertyFieldEditor(
                      label: 'Elevation',
                      initialValue:
                          themeController.elevation.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              elevation: double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Border Width',
                      initialValue:
                          themeController.borderWidth.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              borderWidth:
                                  double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Border Color',
                      initialValue:
                          'Color(0x${themeController.borderColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()})',
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'Color\(0x([a-fA-F0-9]{8})\)')
                            .firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              borderColor: Color(
                                  int.parse(match.group(1)!, radix: 16)));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // --- Filters ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    PropertyFieldEditor(
                      label: 'Opacity',
                      initialValue: themeController.opacity.toStringAsFixed(2),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              opacity: double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Backdrop Blur',
                      initialValue: themeController.blur.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              blur: double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // --- Typography ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                child: const Text('TYPOGRAPHY',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          flex: 4,
                          child: Text('Font Family',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 6,
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: themeController.fontFamily,
                                iconSize: 16,
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                items: [
                                  if (themeController.fontFamily == 'Ahem')
                                    const DropdownMenuItem(
                                        value: 'Ahem',
                                        child: Text('Ahem (Test)')),
                                  const DropdownMenuItem(
                                      value: 'Noto Sans JP',
                                      child: Text('Noto Sans (Default)')),
                                  const DropdownMenuItem(
                                      value: 'Roboto', child: Text('Roboto')),
                                  const DropdownMenuItem(
                                      value: 'Montserrat',
                                      child: Text('Montserrat')),
                                  const DropdownMenuItem(
                                      value: 'Playfair Display',
                                      child: Text('Playfair')),
                                  const DropdownMenuItem(
                                      value: 'Lora', child: Text('Lora')),
                                  const DropdownMenuItem(
                                      value: 'Oswald', child: Text('Oswald')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    themeController.updateTheme(font: val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Base Size',
                      initialValue:
                          themeController.baseFontSize.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              fontSize: double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Scale Ratio',
                      initialValue:
                          themeController.scaleRatio.toStringAsFixed(2),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              ratio: double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Font Weight',
                      initialValue: themeController.fontWeight
                          .toDouble()
                          .toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              weight: double.tryParse(match.group(1)!)
                                  ?.toInt());
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    PropertyFieldEditor(
                      label: 'Letter Spacing',
                      initialValue:
                          themeController.letterSpacing.toStringAsFixed(1),
                      isAppToken: true,
                      onSubmit: (v) {
                        final match = RegExp(r'(-?\d+\.\d+)').firstMatch(v) ??
                            RegExp(r'(-?\d+)').firstMatch(v);
                        if (match != null) {
                          themeController.updateTheme(
                              letterSpace:
                                  double.tryParse(match.group(1)!));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Export Code (Save)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeController.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () =>
                      onExportAndSaveCode(context, themeController),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      showCanvasCommitDialog(context, themeController),
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Commit & Push Design'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: themeController.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
