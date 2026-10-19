import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'main_screen.dart';

/// 직원 로그인 화면. 계정은 관리자가 만들어 알려 줍니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await AuthService.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: kPrimaryGreen, width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: kPrimaryGreenDark),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 96,
                        height: 96,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '내 환자의 모든 것',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '직원 계정으로 로그인하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('이메일', Icons.mail_outline),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? '이메일을 입력해 주세요'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hide,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _decoration(
                        '비밀번호',
                        Icons.lock_outline,
                        suffix: IconButton(
                          tooltip: _hide ? '비밀번호 보기' : '비밀번호 숨기기',
                          icon: Icon(
                            _hide ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kNoShowRed),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('로그인', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '계정이 없거나 비밀번호를 잊었으면 원장님(관리자)에게 문의하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
