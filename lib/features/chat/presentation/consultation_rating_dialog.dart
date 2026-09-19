import 'package:flutter/material.dart';

class ConsultationRatingResult {
  const ConsultationRatingResult({
    required this.rating,
    this.comment,
  });

  final int rating;
  final String? comment;
}

Future<ConsultationRatingResult?> showConsultationRatingDialog(
  BuildContext context, {
  required String doctorName,
}) {
  return showDialog<ConsultationRatingResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ConsultationRatingDialog(doctorName: doctorName),
  );
}

class _ConsultationRatingDialog extends StatefulWidget {
  const _ConsultationRatingDialog({required this.doctorName});

  final String doctorName;

  @override
  State<_ConsultationRatingDialog> createState() =>
      _ConsultationRatingDialogState();
}

class _ConsultationRatingDialogState extends State<_ConsultationRatingDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate your consultation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your experience with Dr. ${widget.doctorName}?',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Optional comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: _rating < 1
              ? null
              : () {
                  Navigator.of(context).pop(
                    ConsultationRatingResult(
                      rating: _rating,
                      comment: _commentController.text.trim(),
                    ),
                  );
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
