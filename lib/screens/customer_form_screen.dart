import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/customer.dart';
import '../theme.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String _gender = '여';

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _gender = c?.gender ?? '여';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final base =
        widget.customer ??
        Customer(
          name: '',
          phone: '',
          gender: _gender,
          createdAt: DateTime.now(),
        );

    final result = base.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _gender,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: kPrimaryGreen, size: 72),
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
                backgroundColor: kPrimaryGreen,
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

  InputDecoration _fieldDecoration(String label, {String? hint, Widget? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: kPrimaryGreen.withValues(alpha: 0.5)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: kPrimaryGreen, width: 2),
      ),
      floatingLabelStyle: const TextStyle(color: kPrimaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? '고객 정보 수정' : '새 고객 등록'),
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
            // 고객명
            TextFormField(
              controller: _nameController,
              decoration: _fieldDecoration(
                '고객명',
                icon: const Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '고객명을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 전화번호
            TextFormField(
              controller: _phoneController,
              decoration: _fieldDecoration(
                '전화번호',
                hint: '010-0000-0000',
                icon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
              ],
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '전화번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // 성별
            Text('성별', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _GenderChip(
                  label: '여',
                  selected: _gender == '여',
                  onTap: () => setState(() => _gender = '여'),
                ),
                const SizedBox(width: 12),
                _GenderChip(
                  label: '남',
                  selected: _gender == '남',
                  onTap: () => setState(() => _gender = '남'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditing ? '수정 완료' : '저장하기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryGreenDark,
                      side: const BorderSide(color: kPrimaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kPrimaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? kPrimaryGreen : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
