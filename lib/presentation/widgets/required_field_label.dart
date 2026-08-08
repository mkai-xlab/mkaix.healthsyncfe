import 'package:flutter/material.dart';

class RequiredFieldLabel extends StatelessWidget {
  final String label;
  final TextStyle? style;

  const RequiredFieldLabel(this.label, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;

    return RichText(
      text: TextSpan(
        style: effectiveStyle,
        children: [
          TextSpan(text: label),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFE53E3E)),
          ),
        ],
      ),
    );
  }
}
