import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class OtpPinInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  const OtpPinInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpPinInput> createState() => _OtpPinInputState();
}

class _OtpPinInputState extends State<OtpPinInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    // Handle full paste
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
        }
      }
      final fullCode = _currentCode;
      widget.onChanged?.call(fullCode);
      if (fullCode.length == widget.length) {
        _focusNodes.last.unfocus();
        widget.onCompleted(fullCode);
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final fullCode = _currentCode;
    widget.onChanged?.call(fullCode);
    if (fullCode.length == widget.length) {
      widget.onCompleted(fullCode);
    }
    setState(() {});
  }

  void _onKeyDown(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
      widget.onChanged?.call(_currentCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final hasValue = _controllers[index].text.isNotEmpty;

        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) => _onKeyDown(event, index),
          child: Container(
            width: 44,
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFocused
                    ? AppColors.primary
                    : (hasValue ? AppColors.borderStrong : AppColors.borderSubtle),
                width: isFocused ? 2.0 : 1.2,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 12,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                cursorColor: AppColors.primary,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => _onChanged(val, index),
              ),
            ),
          ),
        );
      }),
    );
  }
}
