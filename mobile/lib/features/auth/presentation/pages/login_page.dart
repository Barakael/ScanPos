import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/utils/validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        body: Directionality(
          textDirection: TextDirection.ltr,
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                context.go(RouteNames.dashboard);
              } else if (state is AuthUnauthenticated) {
                _showSnack(context, 'Authentication failed');
              } else if (state is AuthPhoneVerificationRequired) {
                _showSnack(
                  context,
                  'Phone verification is not available for this deployment.',
                );
              } else if (state is AuthError) {
                _showSnack(context, state.message);
              }
            },
            child: Stack(
              children: [
                // Glow blobs
                Positioned(
                  top: -100,
                  left: -80,
                  child: _blob(const Color(0xFF3B82F6).withOpacity(0.22), 360),
                ),
                Positioned(
                  bottom: size.height * 0.22,
                  right: -60,
                  child: _blob(const Color(0xFF06B6D4).withOpacity(0.16), 240),
                ),
                Positioned(
                  top: size.height * 0.38,
                  left: -40,
                  child: _blob(const Color(0xFF8B5CF6).withOpacity(0.1), 180),
                ),

                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top bar ──────────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 28, 24, 0),
                            child: Row(
                              children: [
                                // Logo
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF0EA5E9)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3B82F6)
                                            .withOpacity(0.45),
                                        blurRadius: 18,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.asset(
                                      'assets/images/logo/logo.png',
                                      fit: BoxFit.contain,
                                      width: 30,
                                      height: 30,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.point_of_sale_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tera POS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    Text(
                                      'Point of Sale',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 44),

                          // ── Headline ─────────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: -0.9,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to manage your store',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.42),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ── Card ──────────────────────────────────────
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32),
                                ),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 32, 24, 24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FieldLabel(label: 'Email'),
                                      const SizedBox(height: 8),
                                      Focus(
                                        onFocusChange: (v) => setState(
                                            () => _emailFocused = v),
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: Validators.email,
                                          textInputAction:
                                              TextInputAction.next,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: _fieldDecoration(
                                            hint: 'you@example.com',
                                            icon: Icons
                                                .alternate_email_rounded,
                                            focused: _emailFocused,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const _FieldLabel(label: 'Password'),
                                      const SizedBox(height: 8),
                                      Focus(
                                        onFocusChange: (v) => setState(
                                            () => _passwordFocused = v),
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          validator: Validators.password,
                                          textInputAction:
                                              TextInputAction.done,
                                          onFieldSubmitted: (_) => _submit(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: _fieldDecoration(
                                            hint: '••••••••',
                                            icon:
                                                Icons.lock_outline_rounded,
                                            focused: _passwordFocused,
                                            suffix: GestureDetector(
                                              onTap: () => setState(() =>
                                                  _obscurePassword =
                                                      !_obscurePassword),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(
                                                        14),
                                                child: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color: const Color(
                                                      0xFF94A3B8),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Forgot password
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {},
                                          style: TextButton.styleFrom(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 4),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Sign in button
                                      BlocBuilder<AuthBloc, AuthState>(
                                        builder: (context, state) =>
                                            _SignInButton(
                                          isLoading: state is AuthLoading,
                                          onPressed: _submit,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    required bool focused,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          icon,
          color: focused ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
          size: 20,
        ),
      ),
      prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor:
          focused ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 17, horizontal: 4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFF3B82F6), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
      errorStyle:
          const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
        letterSpacing: 0.1,
      ),
    );
  }
}

class _SignInButton extends StatefulWidget {
  const _SignInButton({required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? const LinearGradient(
                    colors: [Color(0xFFCBD5E1), Color(0xFFCBD5E1)])
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.2),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}