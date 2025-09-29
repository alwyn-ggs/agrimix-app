import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Reusable loading widget with consistent styling
class AppLoading extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;
  final EdgeInsets? padding;

  const AppLoading({
    super.key,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size ?? 40,
              height: size ?? 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? NatureColors.primaryGreen,
                ),
                strokeWidth: 3,
              ),
            ),
            if (showMessage && message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: NatureColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full screen loading overlay
class AppLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;
  final Color? backgroundColor;

  const AppLoadingOverlay({
    super.key,
    this.message,
    this.isVisible = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: const AppLoading(
        message: 'Loading...',
        showMessage: true,
      ),
    );
  }
}

/// Inline loading indicator for buttons and forms
class AppLoadingInline extends StatelessWidget {
  final String? text;
  final double size;
  final Color? color;

  const AppLoadingInline({
    super.key,
    this.text,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? NatureColors.primaryGreen,
            ),
            strokeWidth: 2,
          ),
        ),
        if (text != null) ...[
          const SizedBox(width: 8),
          Text(
            text!,
            style: TextStyle(
              fontSize: 14,
              color: color ?? NatureColors.mediumGray,
            ),
          ),
        ],
      ],
    );
  }
}

/// Loading state wrapper for any widget
class AppLoadingWrapper extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Widget? loadingWidget;

  const AppLoadingWrapper({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? 
        AppLoading(message: loadingMessage);
    }
    return child;
  }
}
