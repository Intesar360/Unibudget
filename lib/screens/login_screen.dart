import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_in.dart';

/// Login / Sign up — v3 final fix.
///
/// Seamless by design: the WHOLE page is one gradient
/// (navy -> royal -> teal). There is no white sheet card
/// on top of a banner, so there are no rounded-corner gaps
/// and no black corners at any junction — hero, logo,
/// tagline and form all sit on the same background.
///
/// Labels never float: each field has a small label ABOVE
/// it and hint text inside it. No labelText is used anywhere
/// on this screen, and the theme also sets floating labels
/// to never, so the old "label half in / half out of the
/// box" glitch cannot happen on Email, Password or Full name.
///
/// Tagline (user's own wording): "Master your money, one
/// Taka at a time."
///
/// Logo: the user's own logo image (assets/unibudget_logo.png,
/// white tile with the blue/teal U and ৳ coin), shown with
/// rounded corners. If the asset is missing for any reason,
/// a plain U mark is shown instead of crashing.
///
/// Behaviour is unchanged: any valid email + 6+ char
/// password signs in; the name (sign-up) or email prefix
/// (login) becomes the Home greeting.
class LoginScreen extends StatefulWidget {
  final void Function(String displayName) onAuthenticated;

  const LoginScreen({super.key, required this.onAuthenticated});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// v3.8 test build: login/sign-up now talks to the
  /// friend's Django backend (JWT), instead of the old
  /// demo gate that accepted any email + 6+ chars.
  /// On success the backend returns the display name
  /// and the tokens are kept in ApiService for all
  /// transaction calls. On failure a SnackBar shows
  /// the backend's message (e.g. invalid credentials,
  /// or "could not reach backend" if Django is not
  /// running / the LAN IP is wrong).
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final displayName = _isSignUp
          ? await ApiService.register(
              name: _nameController.text.trim(),
              email: email,
              password: password,
            )
          : await ApiService.login(email: email, password: password);
      if (!mounted) return;
      widget.onAuthenticated(displayName);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not reach the backend. Is Django running '
            'on your PC, and is the LAN IP in api_service.dart correct?',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: AppTheme.royal),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.loginGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/unibudget_logo.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: AppTheme.buttonGradient,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Center(
                                child: Text(
                                  'U',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeSlideIn(
                    delay: Duration(milliseconds: 50),
                    child: Text(
                      'UniBudget',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Master your money, one Taka at a time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 32),
                  FadeSlideIn(
                    delay: Duration(milliseconds: 100),
                    child: Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your money, in one clean place.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 24),
                  if (_isSignUp) ...[
                    _fieldLabel('Full name'),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: AppTheme.ink),
                      decoration: _fieldDecoration(
                        hint: 'Enter your full name',
                        icon: Icons.person_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                    ),
                    SizedBox(height: 16),
                  ],
                  _fieldLabel('Email'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppTheme.ink),
                    decoration: _fieldDecoration(
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      final email = v?.trim() ?? '';
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _fieldLabel('Password'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: AppTheme.ink),
                    decoration: _fieldDecoration(
                      hint: 'Enter your password',
                      icon: Icons.lock_outlined,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.royal,
                        ),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  SizedBox(height: 24),
                  FadeSlideIn(
                    delay: Duration(milliseconds: 200),
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: Icon(Icons.arrow_forward, size: 20),
                        label: Text(
                          _isSignUp ? 'Create account' : 'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.royal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Login'
                          : "Don't have an account? Sign up",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
