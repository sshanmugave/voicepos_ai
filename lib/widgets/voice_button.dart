import 'package:flutter/material.dart';

class VoiceButton extends StatelessWidget {
  const VoiceButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  final bool isListening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 124,
        height: 124,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening ? colorScheme.error : colorScheme.primary,
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              color: (isListening ? colorScheme.error : colorScheme.primary)
                  .withValues(alpha: 0.28),
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
          size: 52,
          color: Colors.white,
        ),
      ),
    );
  }
}