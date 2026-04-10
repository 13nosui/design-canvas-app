// ScreenCardHeader — header strip above each screen card on the canvas.
// Shows screen name, state-variation dropdown, and code button.

import 'package:flutter/material.dart';

import '../../core/design_system/theme_controller.dart';
import 'screen_card_header.styles.dart';

class ScreenCardHeader extends StatelessWidget {
  const ScreenCardHeader({
    super.key,
    required this.screenName,
    required this.mockState,
    required this.onStateChanged,
    required this.onCodeTap,
  });

  final String screenName;
  final MockUIState mockState;
  final ValueChanged<MockUIState> onStateChanged;
  final VoidCallback onCodeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ScreenCardHeaderStyles.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: ScreenCardHeaderStyles.background,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ScreenCardHeaderStyles.borderRadius)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(screenName,
                style: ScreenCardHeaderStyles.nameStyle,
                maxLines: 1),
          ),
          // State dropdown
          SizedBox(
            height: 24,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MockUIState>(
                value: mockState,
                isDense: true,
                dropdownColor: ScreenCardHeaderStyles.background,
                style: ScreenCardHeaderStyles.stateStyle,
                iconSize: 14,
                icon: const Icon(Icons.arrow_drop_down,
                    color: ScreenCardHeaderStyles.iconColor, size: 14),
                items: MockUIState.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(_stateLabel(s),
                        style: ScreenCardHeaderStyles.stateStyle),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onStateChanged(v);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Code button
          InkWell(
            onTap: onCodeTap,
            child: const Icon(Icons.code,
                size: 14, color: ScreenCardHeaderStyles.iconColor),
          ),
        ],
      ),
    );
  }

  static String _stateLabel(MockUIState state) {
    switch (state) {
      case MockUIState.normal:
        return 'Normal';
      case MockUIState.loading:
        return 'Loading';
      case MockUIState.empty:
        return 'Empty';
      case MockUIState.error:
        return 'Error';
    }
  }
}

/// Overlay rendered on top of screen content when mock state != normal.
class MockStateOverlay extends StatelessWidget {
  const MockStateOverlay({super.key, required this.state, required this.child});

  final MockUIState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (state == MockUIState.normal) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.85),
            child: Center(child: _buildStateWidget()),
          ),
        ),
      ],
    );
  }

  Widget _buildStateWidget() {
    switch (state) {
      case MockUIState.normal:
        return const SizedBox.shrink();
      case MockUIState.loading:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('Loading...', style: TextStyle(
                fontSize: 12, color: Color(0xFF64748B))),
          ],
        );
      case MockUIState.empty:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 8),
            Text('No data', style: TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        );
      case MockUIState.error:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
            SizedBox(height: 8),
            Text('Something went wrong', style: TextStyle(
                fontSize: 12, color: Color(0xFFEF4444))),
          ],
        );
    }
  }
}
