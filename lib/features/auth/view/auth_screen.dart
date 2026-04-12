import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _loginFormKey    = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailCtrl = TextEditingController(text: 'admin@freightflow.in');
  final _loginPassCtrl  = TextEditingController(text: 'admin123');
  final _regNameCtrl    = TextEditingController();
  final _regEmailCtrl   = TextEditingController();
  final _regPassCtrl    = TextEditingController();
  final _regConfCtrl    = TextEditingController();

  bool _loginPassVisible = false;
  bool _regPassVisible   = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_loginEmailCtrl, _loginPassCtrl, _regNameCtrl, _regEmailCtrl, _regPassCtrl, _regConfCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // ── Hero header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradBlue,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Real FreightFlow logo — white background matches the logo card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Image.asset('assets/logo.png', height: 56, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                const Text('FreightFlow',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(height: 4),
                Text('Transport Management System',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              ]),
            ),

            // ── Card ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(children: [
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: TabBar(
                        controller: _tabs,
                        indicator: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabs,
                      children: [_loginForm(), _registerForm()],
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Consumer<AuthProvider>(builder: (_, auth, __) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _loginFormKey,
          child: Column(children: [
            _field(controller: _loginEmailCtrl, label: 'Email', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress, validator: _emailValidator),
            const SizedBox(height: 14),
            _field(
              controller: _loginPassCtrl, label: 'Password', icon: Icons.lock_outline,
              obscure: !_loginPassVisible,
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
              suffix: IconButton(
                icon: Icon(_loginPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20, color: AppColors.textMuted),
                onPressed: () => setState(() => _loginPassVisible = !_loginPassVisible),
              ),
            ),
            const SizedBox(height: 8),
            if (auth.status == AuthStatus.error) _errorBanner(auth.error ?? 'Login failed'),
            const Spacer(),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: auth.isLoading ? null : _doLogin,
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In'),
            )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.info),
                SizedBox(width: 6),
                Text('Demo: admin@freightflow.in / admin123',
                    style: TextStyle(fontSize: 11, color: AppColors.info)),
              ]),
            ),
          ]),
        ),
      );
    });
  }

  Widget _registerForm() {
    return Consumer<AuthProvider>(builder: (_, auth, __) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Form(
          key: _registerFormKey,
          child: Column(children: [
            _field(controller: _regNameCtrl, label: 'Full Name', icon: Icons.person_outline,
                validator: AppValidators.personName),
            const SizedBox(height: 12),
            _field(controller: _regEmailCtrl, label: 'Email', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress, validator: _emailValidator),
            const SizedBox(height: 12),
            _field(controller: _regPassCtrl, label: 'Password', icon: Icons.lock_outline,
                obscure: !_regPassVisible,
                validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                suffix: IconButton(
                  icon: Icon(_regPassVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
                  onPressed: () => setState(() => _regPassVisible = !_regPassVisible),
                )),
            const SizedBox(height: 12),
            _field(controller: _regConfCtrl, label: 'Confirm Password', icon: Icons.lock_outline,
                obscure: true,
                validator: (v) => v != _regPassCtrl.text ? 'Passwords do not match' : null),
            if (auth.status == AuthStatus.error) ...[const SizedBox(height: 8), _errorBanner(auth.error ?? 'Failed')],
            const Spacer(),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: auth.isLoading ? null : _doRegister,
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account'),
            )),
          ]),
        ),
      );
    });
  }

  Widget _field({
    required TextEditingController controller,
    required String label, required IconData icon,
    TextInputType? keyboardType, bool obscure = false,
    Widget? suffix, String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          suffixIcon: suffix),
      validator: validator,
    );
  }

  Widget _errorBanner(String msg) => Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.danger))),
    ]),
  );

  String? _emailValidator(String? v) =>
      AppValidators.email(v, allowDemo: true);

  void _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    context.read<AuthProvider>().clearError();
    await context.read<AuthProvider>().login(
        email: _loginEmailCtrl.text.trim(), password: _loginPassCtrl.text);
  }

  void _doRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    context.read<AuthProvider>().clearError();
    await context.read<AuthProvider>().register(
        email: _regEmailCtrl.text.trim(), name: _regNameCtrl.text.trim(), password: _regPassCtrl.text);
  }
}
