// Editing widgets for ImportPage: tap-to-edit text + structural screens
// list with add/remove. Split out of import_page.dart so that the main
// page file stays under the 800-line discipline.
//
// Public surface consumed by `import_page.dart`:
//   - EditAtPath           typedef
//   - EditableField         text that opens an edit dialog on tap
//   - ScreensList          the screens editor with add/remove for both
//                          screens and their sections
//   - ApisList             editable detail.apis list with add/remove
//   - StackChips           editable detail.stack chips with add/remove
//
// Everything else is private to this file.

import 'package:flutter/material.dart';

import 'import_page.styles.dart';

/// Callback that mutates the payload at a nested path.
/// See `_ImportPageState._editAtPath` for the path format — a list of
/// `String` map keys and `int` list indices.
typedef EditAtPath = void Function(List<Object> path, String newValue);

/// A Text that, when tapped, opens an edit dialog and calls [onChanged]
/// with the new value. Designed to drop-in replace any Text in the
/// ImportPage body — pencil icon is inlined via WidgetSpan so it does not
/// break surrounding layouts.
class EditableField extends StatelessWidget {
  const EditableField({
    super.key,
    required this.value,
    required this.style,
    required this.label,
    required this.onChanged,
    this.multiline = false,
  });
  final String value;
  final TextStyle style;
  final String label;
  final ValueChanged<String> onChanged;
  final bool multiline;

  Future<void> _openEditor(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditDialog(
        label: label,
        initialValue: value,
        multiline: multiline,
      ),
    );
    if (result != null && result != value) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEditor(context),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: value.isEmpty ? '(タップして追加)' : value, style: style),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: Color(0x552563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.label,
    required this.initialValue,
    required this.multiline,
  });
  final String label;
  final String initialValue;
  final bool multiline;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.multiline ? null : 1,
        minLines: widget.multiline ? 3 : 1,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onSubmitted: widget.multiline
            ? null
            : (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class ScreensList extends StatelessWidget {
  const ScreensList({
    super.key,
    required this.screens,
    required this.onEdit,
    required this.onAddScreen,
    required this.onRemoveScreen,
    required this.onDuplicateScreen,
    required this.onMoveScreen,
    required this.onAddSection,
    required this.onRemoveSection,
  });
  final List<Map<String, dynamic>> screens;
  final EditAtPath onEdit;
  final VoidCallback onAddScreen;
  final ValueChanged<int> onRemoveScreen;
  final ValueChanged<int> onDuplicateScreen;
  final void Function(int from, int to) onMoveScreen;
  final ValueChanged<int> onAddSection;
  final void Function(int screenIndex, int sectionIndex) onRemoveSection;

  static List<Map<String, dynamic>> _asListOfMaps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...screens.asMap().entries.map((entry) {
          final screenIndex = entry.key;
          final s = entry.value;
          final name = (s['name'] as String?) ?? '';
          final purpose = (s['purpose'] as String?) ?? '';
          final sections = _asListOfMaps(s['sections']);
          return Container(
            margin: const EdgeInsets.only(bottom: ImportPageStyles.itemGap),
            padding: ImportPageStyles.cardPadding,
            decoration: ImportPageStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: EditableField(
                        value: name,
                        style: ImportPageStyles.itemTitleStyle,
                        label: '画面名',
                        onChanged: (v) => onEdit(
                          ['detail', 'screens', screenIndex, 'name'],
                          v,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: '上へ移動',
                      child: InkWell(
                        onTap: screenIndex == 0
                            ? null
                            : () => onMoveScreen(screenIndex, screenIndex - 1),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_upward,
                            size: 14,
                            color: screenIndex == 0
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: '下へ移動',
                      child: InkWell(
                        onTap: screenIndex == screens.length - 1
                            ? null
                            : () => onMoveScreen(screenIndex, screenIndex + 1),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_downward,
                            size: 14,
                            color: screenIndex == screens.length - 1
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'この画面を複製',
                      child: InkWell(
                        onTap: () => onDuplicateScreen(screenIndex),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.content_copy,
                              size: 14, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    _DeleteIconButton(
                      tooltip: 'この画面を削除',
                      onPressed: () => _confirmRemoveScreen(
                        context,
                        name,
                        () => onRemoveScreen(screenIndex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                EditableField(
                  value: purpose,
                  style: ImportPageStyles.itemBodyStyle,
                  label: '画面の目的',
                  multiline: true,
                  onChanged: (v) => onEdit(
                    ['detail', 'screens', screenIndex, 'purpose'],
                    v,
                  ),
                ),
                const SizedBox(height: 10),
                ...sections.asMap().entries.map(
                      (secEntry) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _SectionSubCard(
                          label: (secEntry.value['label'] as String?) ?? '',
                          body: (secEntry.value['body'] as String?) ?? '',
                          onEditLabel: (v) => onEdit(
                            [
                              'detail',
                              'screens',
                              screenIndex,
                              'sections',
                              secEntry.key,
                              'label',
                            ],
                            v,
                          ),
                          onEditBody: (v) => onEdit(
                            [
                              'detail',
                              'screens',
                              screenIndex,
                              'sections',
                              secEntry.key,
                              'body',
                            ],
                            v,
                          ),
                          onRemove: () =>
                              onRemoveSection(screenIndex, secEntry.key),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('セクション追加'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                    onPressed: () => onAddSection(screenIndex),
                  ),
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('画面を追加'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onAddScreen,
        ),
      ],
    );
  }
}

Future<void> _confirmRemoveScreen(
  BuildContext context,
  String name,
  VoidCallback onConfirmed,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('画面を削除'),
      content: Text('「${name.isEmpty ? '無題' : name}」を削除しますか?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('削除'),
        ),
      ],
    ),
  );
  if (confirmed == true) onConfirmed();
}

class _DeleteIconButton extends StatelessWidget {
  const _DeleteIconButton({required this.tooltip, required this.onPressed});
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

class _SectionSubCard extends StatelessWidget {
  const _SectionSubCard({
    required this.label,
    required this.body,
    required this.onEditLabel,
    required this.onEditBody,
    required this.onRemove,
  });
  final String label;
  final String body;
  final ValueChanged<String> onEditLabel;
  final ValueChanged<String> onEditBody;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: EditableField(
                  value: label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Color(0xFF475569),
                  ),
                  label: 'セクションラベル',
                  onChanged: onEditLabel,
                ),
              ),
              _DeleteIconButton(
                tooltip: 'このセクションを削除',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          EditableField(
            value: body,
            style: ImportPageStyles.itemBodyStyle,
            label: 'セクション本文',
            multiline: true,
            onChanged: onEditBody,
          ),
        ],
      ),
    );
  }
}

class ApisList extends StatelessWidget {
  const ApisList({
    super.key,
    required this.apis,
    required this.onEdit,
    required this.onAdd,
    required this.onRemove,
  });
  final List<Map<String, dynamic>> apis;
  final EditAtPath onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...apis.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          final name = (a['name'] as String?) ?? '';
          final description = (a['description'] as String?) ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: ImportPageStyles.itemGap),
            padding: ImportPageStyles.cardPadding,
            decoration: ImportPageStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ImportPageStyles.apiCodeBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: EditableField(
                          value: name,
                          style: ImportPageStyles.apiCodeStyle,
                          label: 'API 名',
                          onChanged: (v) =>
                              onEdit(['detail', 'apis', i, 'name'], v),
                        ),
                      ),
                    ),
                    _DeleteMini(onPressed: () => onRemove(i)),
                  ],
                ),
                const SizedBox(height: 6),
                EditableField(
                  value: description,
                  style: ImportPageStyles.itemBodyStyle,
                  label: 'API の説明',
                  multiline: true,
                  onChanged: (v) =>
                      onEdit(['detail', 'apis', i, 'description'], v),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 14),
            label: const Text('API を追加'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }
}

class StackChips extends StatelessWidget {
  const StackChips({
    super.key,
    required this.stack,
    required this.onEdit,
    required this.onAdd,
    required this.onRemove,
  });
  final List<String> stack;
  final EditAtPath onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...stack.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            decoration: BoxDecoration(
              color: ImportPageStyles.chipBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EditableField(
                  value: s,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ImportPageStyles.chipForeground,
                  ),
                  label: 'スタック項目',
                  onChanged: (v) => onEdit(['detail', 'stack', i], v),
                ),
                _DeleteMini(onPressed: () => onRemove(i)),
              ],
            ),
          );
        }),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 12, color: Color(0xFF64748B)),
                SizedBox(width: 4),
                Text(
                  '追加',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteMini extends StatelessWidget {
  const _DeleteMini({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.all(3),
        child: Icon(Icons.close, size: 12, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
