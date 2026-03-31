import 'package:flutter/material.dart';
import 'dart:async';

class PropertyFieldEditor extends StatefulWidget {
  final String label;
  final String initialValue;
  final bool isAppToken;
  final void Function(String) onSubmit;

  const PropertyFieldEditor({
    super.key,
    required this.label,
    required this.initialValue,
    required this.isAppToken,
    required this.onSubmit,
  });

  @override
  State<PropertyFieldEditor> createState() => _PropertyFieldEditorState();
}

class _PropertyFieldEditorState extends State<PropertyFieldEditor> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  bool _isColorMode = false;
  Color? _parsedColor;
  bool _isColorPickerOpen = false;

  bool _isNumberMode = false;
  double? _parsedNumber;
  String _numPrefix = '';
  String _numSuffix = '';

  Timer? _debounce;
  bool _isPanelActive = false;

  bool get _isIntegerOnly {
    return [
      'Spacing Base',
      'Border Radius',
      'Elevation',
      'Border Width',
      'Base Size',
      'Font Weight'
    ].contains(widget.label);
  }

  double get _sliderMin {
    if (widget.label == 'Opacity') return 0.0;
    if (widget.label == 'Font Weight') return 100.0;
    if (widget.label == 'Scale Ratio') return 1.0;
    if (widget.label == 'Letter Spacing') return -5.0;
    return 0.0;
  }

  double get _sliderMax {
    if (widget.label == 'Opacity') return 1.0;
    if (widget.label == 'Font Weight') return 900.0;
    if (widget.label == 'Spacing Base') return 64.0;
    if (widget.label == 'Border Radius') return 100.0;
    if (widget.label == 'Elevation') return 24.0;
    if (widget.label == 'Border Width') return 16.0;
    if (widget.label == 'Base Size') return 64.0;
    if (widget.label == 'Scale Ratio') return 2.0;
    if (widget.label == 'Letter Spacing') return 10.0;
    if (widget.label == 'Backdrop Blur') return 40.0;
    return 100.0;
  }

  int? get _sliderDivisions {
    if (widget.label == 'Font Weight') return 8; // 100, 200, ... 900
    if (widget.label == 'Opacity') return 100; // 0.01 step
    if (_isIntegerOnly) {
      final range = (_sliderMax - _sliderMin).toInt();
      return range > 0 ? range : null;
    }
    if (widget.label == 'Scale Ratio') return 100; // 0.01 step
    if (widget.label == 'Letter Spacing') return 150; // 0.1 step
    if (widget.label == 'Backdrop Blur') return 80; // 0.5 step
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _parseInitialValue(widget.initialValue);

    _focusNode.addListener(() {
      setState(() {});
      // FocusNodeが外れても、パネル外タップ(TapRegion)まで状態を維持する
    });
  }

  @override
  void didUpdateWidget(covariant PropertyFieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      if (_focusNode.hasFocus) return; // do not overwrite while user is editing
      _controller.text = widget.initialValue;
      _parseInitialValue(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _parseInitialValue(String text) {
    _isColorMode = false;
    _isNumberMode = false;

    // Check Color format Color(0xFF...)
    final colorMatch = RegExp(r'Color\(0x([a-fA-F0-9]{8})\)').firstMatch(text);
    if (colorMatch != null) {
      _isColorMode = true;
      final hexStr = colorMatch.group(1)!;
      _parsedColor = Color(int.parse(hexStr, radix: 16));
      return;
    }

    // Check Number format (extract first valid floating point number or integer)
    final numMatch = RegExp(r'(-?\d+\.\d+)').firstMatch(text) ??
        RegExp(r'(-?\d+)').firstMatch(text);
    if (numMatch != null) {
      _isNumberMode = true;
      _parsedNumber = double.parse(numMatch.group(1)!);
      if (_isIntegerOnly) {
        _parsedNumber = _parsedNumber!.roundToDouble();
      }
      _numPrefix = text.substring(0, numMatch.start);
      _numSuffix = text.substring(numMatch.end);
      return;
    }
  }

  void _submitCurrent() {
    widget.onSubmit(_controller.text);
  }

  void _onSliderChanged(double val) {
    setState(() {
      _parsedNumber = val;
      if (_isIntegerOnly) {
        _parsedNumber = val.roundToDouble();
      }

      String strVal;
      if (_isIntegerOnly) {
        strVal = _parsedNumber!.toInt().toString();
      } else if (widget.label == 'Opacity' || widget.label == 'Scale Ratio') {
        strVal = _parsedNumber!.toStringAsFixed(2);
      } else {
        strVal = _parsedNumber!.toStringAsFixed(1);
      }

      _controller.text = '$_numPrefix$strVal$_numSuffix';
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _submitCurrent();
    });
  }

  void _onColorSliderChanged(double hue) {
    if (_parsedColor == null) return;
    final hsl = HSLColor.fromColor(_parsedColor!);
    setState(() {
      _parsedColor = hsl.withHue(hue).toColor();
      final hexStr =
          _parsedColor!.value.toRadixString(16).padLeft(8, '0').toUpperCase();

      // Handle cases where the text uses Color(0xFF...) format natively
      if (_controller.text.contains(RegExp(r'Color\(0x[a-fA-F0-9]{8}\)'))) {
        _controller.text = _controller.text.replaceAll(
            RegExp(r'Color\(0x[a-fA-F0-9]{8}\)'), 'Color(0x$hexStr)');
      } else {
        // AppTokens replacement edge case (if user drags slider on a token, we might convert it to custom value string)
        _controller.text = 'Color(0x$hexStr)';
      }
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _submitCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapInside: (_) {
        if (!_isPanelActive) setState(() => _isPanelActive = true);
      },
      onTapOutside: (_) {
        if (_isPanelActive || _isColorPickerOpen) {
          setState(() {
            _isPanelActive = false;
            _isColorPickerOpen = false;
          });
          _focusNode.unfocus();
          if (_isNumberMode) _submitCurrent();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 5,
                child: _buildInputArea(),
              ),
            ],
          ),

          // Popup Slider for Number Mode
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: (_isNumberMode && _isPanelActive && _parsedNumber != null)
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.linear_scale,
                            size: 12, color: Colors.grey),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 16),
                            ),
                            child: Slider(
                              value:
                                  _parsedNumber!.clamp(_sliderMin, _sliderMax),
                              min: _sliderMin,
                              max: _sliderMax,
                              divisions: _sliderDivisions,
                              onChanged: _onSliderChanged,
                            ),
                          ),
                        ),
                        Text(
                            _isIntegerOnly
                                ? _parsedNumber!.toInt().toString()
                                : (widget.label == 'Opacity' ||
                                        widget.label == 'Scale Ratio'
                                    ? _parsedNumber!.toStringAsFixed(2)
                                    : _parsedNumber!.toStringAsFixed(1)),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Popup Slider for Color Mode
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: (_isColorMode && _isColorPickerOpen && _parsedColor != null)
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        const Text('Hue',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: HSLColor.fromColor(_parsedColor!).hue,
                              min: 0,
                              max: 360,
                              activeColor: _parsedColor,
                              onChanged: _onColorSliderChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _focusNode.hasFocus
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (_isColorMode && _parsedColor != null)
            GestureDetector(
              onTap: () {
                setState(() => _isColorPickerOpen = !_isColorPickerOpen);
              },
              child: Container(
                margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _parsedColor,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black12),
                ),
              ),
            ),
          Expanded(
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: widget.isAppToken
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: InputBorder.none,
              ),
              onFieldSubmitted: (v) {
                _parseInitialValue(v);
                _submitCurrent();
              },
            ),
          ),
        ],
      ),
    );
  }
}
