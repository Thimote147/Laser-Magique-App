import 'package:flutter/material.dart';

/// Dialog de base avec style uniforme
class CustomDialog extends StatelessWidget {
  final String title;
  final Icon? titleIcon;
  final Widget content;
  final List<Widget>? actions;

  const CustomDialog({
    super.key,
    required this.title,
    this.titleIcon,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (titleIcon != null || title.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: titleIcon!,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: content,
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog d'alerte avec icône
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget>? actions;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      titleIcon: icon != null ? Icon(icon, color: iconColor) : null,
      content: Text(content),
      actions: actions,
    );
  }
}

/// Dialog de confirmation
class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? iconColor;
  final Color? confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CustomConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    this.icon,
    this.iconColor,
    this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomDialog(
      title: title,
      titleIcon: icon != null ? Icon(icon, color: iconColor) : null,
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelText),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            foregroundColor: confirmColor ?? theme.colorScheme.primary,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Dialog de chargement
class CustomLoadingDialog extends StatelessWidget {
  final String title;
  final String? message;

  const CustomLoadingDialog({
    super.key,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      titleIcon: const Icon(Icons.hourglass_empty),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}

/// Dialog de succès
class CustomSuccessDialog extends StatefulWidget {
  final String title;
  final String content;
  final bool autoClose;
  final Duration? autoCloseDuration;

  const CustomSuccessDialog({
    super.key,
    required this.title,
    required this.content,
    this.autoClose = false,
    this.autoCloseDuration,
  });

  @override
  State<CustomSuccessDialog> createState() => _CustomSuccessDialogState();
}

class _CustomSuccessDialogState extends State<CustomSuccessDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.autoClose && widget.autoCloseDuration != null) {
      Future.delayed(widget.autoCloseDuration!, () {
        if (mounted && context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {    
    return CustomDialog(
      title: widget.title,
      titleIcon: Icon(
        Icons.check_circle,
        color: Colors.green.shade600,
      ),
      content: Text(widget.content),
      actions: widget.autoClose
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
    );
  }
}

/// Dialog d'erreur
class CustomErrorDialog extends StatelessWidget {
  final String title;
  final String content;

  const CustomErrorDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomDialog(
      title: title,
      titleIcon: Icon(
        Icons.error,
        color: theme.colorScheme.error,
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}