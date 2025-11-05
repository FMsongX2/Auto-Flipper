import 'package:flutter/material.dart';

class EditScoreNameDialog extends StatefulWidget {
  final String initialName;

  const EditScoreNameDialog({
    super.key,
    required this.initialName,
  });

  @override
  State<EditScoreNameDialog> createState() => _EditScoreNameDialogState();
}

class _EditScoreNameDialogState extends State<EditScoreNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('악보 이름 수정'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '악보 이름',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.pop(context, _controller.text);
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

