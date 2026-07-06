import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_logo.dart';

enum _AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.login;
  UserRole _role = UserRole.student;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _instituteCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Pune');

  final _formKey = GlobalKey<FormState>();
  final _googleFormKey = GlobalKey<FormState>();

  String? _message;
  bool _busy = false;

  Color get _accent => AppColors.forRole(_role.key);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _instituteCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _message = null;
      _busy = true;
    });
    final auth = context.read<AuthProvider>();
    final result = _mode == _AuthMode.login
        ? await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text, _role)
        : await auth.signup(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _role,
            name: _nameCtrl.text.trim(),
            instituteName: _instituteCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
          );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result.ok ? null : result.message;
    });
    if (result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_mode == _AuthMode.login ? 'Signed in successfully' : 'Account created successfully'),
        backgroundColor: AppColors.emerald500,
      ));
    } else if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message!),
        backgroundColor: AppColors.rose500,
      ));
    }
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _message = null;
      _busy = true;
    });
    final auth = context.read<AuthProvider>();
    final result = _mode == _AuthMode.signup
        ? await auth.startGoogleSignup(_role)
        : await auth.loginWithGoogle(_role);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result.ok ? null : result.message;
    });
  }

  Future<void> _handleCompleteGoogleSignup() async {
    if (_passwordCtrl.text.length < 6) {
      setState(() => _message = 'Password must be at least 6 characters.');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }
    setState(() {
      _message = null;
      _busy = true;
    });
    final auth = context.read<AuthProvider>();
    final result = await auth.completeGoogleSignup(
      password: _passwordCtrl.text,
      name: _nameCtrl.text.trim(),
      instituteName: _instituteCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result.ok ? null : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pending = auth.pendingGoogleUser;

    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: pending != null
                    ? _buildGooglePasswordStep(pending)
                    : _buildLoginSignupCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String tagline) {
    return Column(
      children: [
        const VedoGradientText('Vedo', fontSize: 26),
        const SizedBox(height: 4),
        Text(tagline, style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
        const SizedBox(height: 16),
      ],
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.slate900.withOpacity(0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.white10),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 40, offset: Offset(0, 20))],
      );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.slate950.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _accent),
        ),
      );

  Widget _buildLoginSignupCard() {
    return Container(
      key: const ValueKey('loginSignup'),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header('Virtual Education Desk Operator'),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.white05,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.white10),
            ),
            child: Row(
              children: [
                _pillTab('Login', _AuthMode.login),
                _pillTab('Sign up', _AuthMode.signup),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _roleDropdown(),
          const SizedBox(height: 12),
          _googleButton(
            label: 'Continue with Google${_mode == _AuthMode.signup ? ' (sign up)' : ''}',
            onTap: _busy ? null : _handleGoogle,
          ),
          _orDivider('or use email'),
          Form(
            key: _formKey,
            child: Column(
              children: [
                if (_mode == _AuthMode.signup) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppColors.slate100),
                    decoration: _fieldDecoration('Your name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (_role == UserRole.owner) ...[
                    TextFormField(
                      controller: _instituteCtrl,
                      style: const TextStyle(color: AppColors.slate100),
                      decoration: _fieldDecoration('Institute name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityCtrl,
                      style: const TextStyle(color: AppColors.slate100),
                      decoration: _fieldDecoration('City'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: _fieldDecoration('Email address'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: _fieldDecoration('Password'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _primaryButton(
                  label: _busy
                      ? 'Please wait...'
                      : (_mode == _AuthMode.login ? 'Login' : 'Create account'),
                  onTap: _busy ? null : _handleSubmit,
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _errorBanner(_message!),
          ],
        ],
      ),
    );
  }

  Widget _buildGooglePasswordStep(PendingGoogleUser pending) {
    return Container(
      key: const ValueKey('googleStep'),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header('One last step'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.indigo600.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.indigo400.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Signing up with', style: TextStyle(fontSize: 13, color: AppColors.slate400)),
                const SizedBox(height: 2),
                Text(pending.email,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate100)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Create a password for your account. You'll be able to log in later with either this password or \"Continue with Google\".",
            style: TextStyle(fontSize: 13, color: AppColors.slate400),
          ),
          const SizedBox(height: 12),
          _roleDropdown(),
          const SizedBox(height: 12),
          Form(
            key: _googleFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: _fieldDecoration('Your name'),
                ),
                if (_role == UserRole.owner) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instituteCtrl,
                    style: const TextStyle(color: AppColors.slate100),
                    decoration: _fieldDecoration('Institute name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityCtrl,
                    style: const TextStyle(color: AppColors.slate100),
                    decoration: _fieldDecoration('City'),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: _fieldDecoration('Create a password (min 6 characters)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.slate100),
                  decoration: _fieldDecoration('Confirm password'),
                ),
                const SizedBox(height: 16),
                _primaryButton(
                  label: _busy ? 'Please wait...' : 'Finish signing up',
                  onTap: _busy ? null : _handleCompleteGoogleSignup,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.read<AuthProvider>().cancelGoogleSignup();
                    _passwordCtrl.clear();
                    _confirmCtrl.clear();
                    setState(() => _message = null);
                  },
                  child: const Text('Cancel', style: TextStyle(color: AppColors.slate400)),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 4),
            _errorBanner(_message!),
          ],
        ],
      ),
    );
  }

  Widget _pillTab(String label, _AuthMode mode) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _mode = mode;
          _message = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.slate300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate950.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.4), width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserRole>(
          value: _role,
          isExpanded: true,
          dropdownColor: AppColors.slate900,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate400),
          style: const TextStyle(color: AppColors.slate100, fontSize: 14),
          items: UserRole.values
              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
              .toList(),
          onChanged: (r) => setState(() => _role = r ?? _role),
        ),
      ),
    );
  }

  Widget _googleButton({required String label, required VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.white10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.g_mobiledata, size: 22, color: Color(0xFF1E293B)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.white10, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppColors.slate500)),
          ),
          const Expanded(child: Divider(color: AppColors.white10, height: 1)),
        ],
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rose500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rose400.withOpacity(0.2)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFFECDD3), fontSize: 13)),
    );
  }
}
