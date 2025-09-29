import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Reusable error widget with consistent styling
class AppError extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Color? iconColor;
  final bool showRetryButton;
  final EdgeInsets? padding;

  const AppError({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.iconColor,
    this.showRetryButton = true,
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
            // Error Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.red).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 48,
                color: iconColor ?? Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // Error Title
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NatureColors.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            
            // Error Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: NatureColors.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Retry Button
            if (showRetryButton && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NatureColors.primaryGreen,
                  foregroundColor: NatureColors.pureWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full screen error page
class AppErrorPage extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final IconData? icon;

  const AppErrorPage({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.onGoBack,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        backgroundColor: NatureColors.natureBackground,
        elevation: 0,
        leading: onGoBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onGoBack,
              )
            : null,
      ),
      body: AppError(
        message: message,
        title: title,
        onRetry: onRetry,
        icon: icon,
        padding: const EdgeInsets.all(32),
      ),
    );
  }
}

/// Inline error message for forms and inputs
class AppErrorInline extends StatelessWidget {
  final String message;
  final bool isVisible;
  final EdgeInsets? padding;

  const AppErrorInline({
    super.key,
    required this.message,
    this.isVisible = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state wrapper for any widget
class AppErrorWrapper extends StatelessWidget {
  final Widget child;
  final String? error;
  final VoidCallback? onRetry;
  final bool showError;
  final Widget? errorWidget;

  const AppErrorWrapper({
    super.key,
    required this.child,
    this.error,
    this.onRetry,
    this.showError = true,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (showError && error != null) {
      return errorWidget ?? 
        AppError(
          message: error!,
          onRetry: onRetry,
        );
    }
    return child;
  }
}

/// Network error specific widget
class AppNetworkError extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const AppNetworkError({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AppError(
      title: 'Connection Error',
      message: customMessage ?? 
        'Unable to connect to the server. Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      iconColor: Colors.orange,
      onRetry: onRetry,
    );
  }
}

/// Permission error specific widget
class AppPermissionError extends StatelessWidget {
  final String permission;
  final VoidCallback? onRequestPermission;

  const AppPermissionError({
    super.key,
    required this.permission,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return AppError(
      title: 'Permission Required',
      message: 'This app needs $permission permission to function properly.',
      icon: Icons.lock_outline,
      iconColor: Colors.amber,
      onRetry: onRequestPermission,
      showRetryButton: onRequestPermission != null,
    );
  }
}
