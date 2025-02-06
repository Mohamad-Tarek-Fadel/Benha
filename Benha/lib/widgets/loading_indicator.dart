import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
} 