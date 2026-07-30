import 'package:flutter/material.dart';

import '../models/idea.dart';

const Color _kPrimaryGreen = Color(0xFF38C77F);

class IdeaFormScreen extends StatefulWidget {
  const IdeaFormScreen({super.key, this.idea});

  final Idea? idea;

  @override
  State<IdeaFormScreen> createState() => _IdeaFormScreenState();
}

class _IdeaFormScreenState extends State<IdeaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool get _isEditing => widget.idea != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.idea?.title ?? '');
    _contentController = TextEditingController(
      text: widget.idea?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = (widget.idea ?? Idea(title: '', content: '', createdAt: DateTime.now()))
        .copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: _kPrimaryGreen, size: 72),
            const SizedBox(height: 16),
            const Text(
              '저장되었습니다!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kPrimaryGreen,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? '아이디어 수정' : '새 아이디어'),
        actions: [
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            tooltip: '저장',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _kPrimaryGreen.withValues(alpha: 0.5)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: _kPrimaryGreen, width: 2),
                ),
                floatingLabelStyle: const TextStyle(color: _kPrimaryGreen),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '내용',
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _kPrimaryGreen.withValues(alpha: 0.5)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: _kPrimaryGreen, width: 2),
                ),
                floatingLabelStyle: const TextStyle(color: _kPrimaryGreen),
                alignLabelWithHint: true,
              ),
              minLines: 6,
              maxLines: 12,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '내용을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditing ? '수정 완료' : '저장하기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('이전'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
