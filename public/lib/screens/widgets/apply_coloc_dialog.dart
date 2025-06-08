import 'package:flutter/material.dart';

class ApplyColocDialog extends StatefulWidget {
  final void Function(String message) onSubmit;
  final bool isLoading;
  const ApplyColocDialog({super.key, required this.onSubmit, this.isLoading = false});

  @override
  State<ApplyColocDialog> createState() => _ApplyColocDialogState();
}

class _ApplyColocDialogState extends State<ApplyColocDialog> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Demande de colocation'),
      content: TextField(
        controller: _messageController,
        decoration: const InputDecoration(
          labelText: 'Message (optionnel)',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: widget.isLoading
              ? null
              : () => widget.onSubmit(_messageController.text.trim()),
          child: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}
