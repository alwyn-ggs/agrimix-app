import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app_error.dart';

/// Error boundary widget to catch and handle unhandled exceptions
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
          _hasError = true;
        });
        widget.onError?.call();
      }
    };
  }

  @override
  void dispose() {
    // Reset global error handling
    FlutterError.onError = FlutterError.presentError;
    super.dispose();
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _stackTrace);
      }

      return AppErrorPage(
        title: 'Something went wrong',
        message: _getErrorMessage(_error!),
        onRetry: _resetError,
        onGoBack: () {
          _resetError();
          Navigator.of(context).pop();
        },
      );
    }

    return widget.child;
  }

  String _getErrorMessage(Object error) {
    if (kDebugMode) {
      return error.toString();
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Error boundary for specific widgets
class WidgetErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? fallbackMessage;
  final VoidCallback? onRetry;

  const WidgetErrorBoundary({
    super.key,
    required this.child,
    this.fallbackMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorBuilder: (context, error, stackTrace) {
        return AppError(
          title: 'Widget Error',
          message: fallbackMessage ?? 'This widget encountered an error.',
          onRetry: onRetry,
          icon: Icons.widgets,
          iconColor: Colors.orange,
        );
      },
      child: child,
    );
  }
}

/// Error boundary for pages
class PageErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? pageName;

  const PageErrorBoundary({
    super.key,
    required this.child,
    this.pageName,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorBuilder: (context, error, stackTrace) {
        return AppErrorPage(
          title: 'Page Error',
          message: '${pageName ?? 'This page'} encountered an error. Please try again.',
          onRetry: () {
            // Reset the error boundary
            Navigator.of(context).pushReplacementNamed(
              ModalRoute.of(context)?.settings.name ?? '/',
            );
          },
          onGoBack: () => Navigator.of(context).pop(),
        );
      },
      child: child,
    );
  }
}

/// Error boundary for async operations
class AsyncErrorBoundary extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRetry;
  final String? errorMessage;

  const AsyncErrorBoundary({
    super.key,
    required this.child,
    this.onRetry,
    this.errorMessage,
  });

  @override
  State<AsyncErrorBoundary> createState() => _AsyncErrorBoundaryState();
}

class _AsyncErrorBoundaryState extends State<AsyncErrorBoundary> {
  bool _hasError = false;
  bool _isRetrying = false;

  void _handleError(Object error) {
    setState(() {
      _hasError = true;
    });
  }

  Future<void> _retry() async {
    if (widget.onRetry == null) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await widget.onRetry!();
      setState(() {
        _hasError = false;
        _isRetrying = false;
      });
    } catch (e) {
      setState(() {
        _isRetrying = false;
      });
      _handleError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AppError(
        title: 'Operation Failed',
        message: widget.errorMessage ?? 
          'The operation failed. Please try again.',
        onRetry: _isRetrying ? null : _retry,
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }

    return widget.child;
  }
}
