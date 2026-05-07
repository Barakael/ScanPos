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
  bool _isLoading = false;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

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
    HapticFeedback.mediumImpact();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
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
    final isSmallScreen = size.width < 600;
    final isWebView = size.width > 900;
    
    // Responsive values
    final logoSize = isSmallScreen ? 42.0 : 56.0;
    final logoPadding = isSmallScreen ? 12.0 : 16.0;
    final titleFontSize = isSmallScreen ? 28.0 : 36.0;
    final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final descriptionFontSize = isSmallScreen ? 16.0 : 18.0;
    final horizontalPadding = isSmallScreen ? 24.0 : 40.0;
    final cardMaxWidth = isWebView ? 480.0 : double.infinity;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            setState(() => _isLoading = state is AuthLoading);

            if (state is AuthAuthenticated) {
              context.go(RouteNames.dashboard);
            } else if (state is AuthUnauthenticated) {
              _showErrorSnack(context, 'Invalid email or password');
            } else if (state is AuthError) {
              _showErrorSnack(context, state.message);
            } else if (state is AuthPhoneVerificationRequired) {
              _showErrorSnack(context, 'Phone verification not supported yet');
            }
          },
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0A0F1E), Color(0xFF1A2332)],
                    ),
                  ),
                ),
              ),

              // Decorative glows
              Positioned(top: -120, left: -80, child: _glowOrb(const Color(0xFF3B82F6), 380)),
              Positioned(bottom: -100, right: -60, child: _glowOrb(const Color(0xFF06B6D4), 320)),
              Positioned(top: size.height * 0.35, left: -50, child: _glowOrb(const Color(0xFF8B5CF6), 200)),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWebView ? 1000 : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isSmallScreen ? 40 : 60),

                              // Logo + Title
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(logoPadding),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)]),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo/logo.png',
                                      width: logoSize,
                                      height: logoSize,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.point_of_sale_rounded,
                                        color: Colors.white,
                                        size: logoSize,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 16 : 24),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tera VFD',
                                          style: TextStyle(
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'Point of Sale System',
                                          style: TextStyle(
                                            fontSize: subtitleFontSize,
                                            color: Colors.white54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: isSmallScreen ? 50 : 70),

                              // Description
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to continue to your dashboard',
                                style: TextStyle(
                                  fontSize: descriptionFontSize,
                                  color: Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 40 : 60),

                              // Login Card - Centered on wide screens
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: cardMaxWidth,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          _ModernTextField(
                                            controller: _emailController,
                                            label: 'Email Address',
                                            hint: 'you@business.com',
                                            icon: Icons.alternate_email_rounded,
                                            keyboardType: TextInputType.emailAddress,
                                            validator: Validators.email,
                                            textInputAction: TextInputAction.next,
                                          ),

                                          SizedBox(height: isSmallScreen ? 20 : 28),

                                          _ModernTextField(
                                            controller: _passwordController,
                                            label: 'Password',
                                            hint: '••••••••',
                                            icon: Icons.lock_outline_rounded,
                                            obscureText: _obscurePassword,
                                            validator: Validators.password,
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: _submit,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                                color: const Color(0xFF64748B),
                                              ),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                          ),

                                          SizedBox(height: isSmallScreen ? 10 : 12),

                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () {},
                                              child: const Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  color: Color(0xFF3B82F6),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: isSmallScreen ? 24 : 32),

                                          _ModernSignInButton(
                                            isLoading: _isLoading,
                                            onPressed: _submit,
                                          ),

                                          SizedBox(height: isSmallScreen ? 20 : 28),

                                          // Register Link
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Don't have an account? ",
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: isSmallScreen ? 14 : 15,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  print('Navigating to register');
                                                  GoRouter.of(context).go('/register');
                                                },
                                                child: Text(
                                                  'Register',
                                                  style: TextStyle(
                                                    color: const Color(0xFF3B82F6),
                                                    fontSize: isSmallScreen ? 14 : 15,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                    decorationColor: const Color(0xFF3B82F6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 30 : 50),

                              Center(
                                child: Text(
                                  '© 2026 Tera POS',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: isSmallScreen ? 11 : 12,
                                  ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 20 : 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.25), Colors.transparent],
          radius: 0.7,
        ),
      ),
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}

// Modern TextField Component
class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback? onFieldSubmitted;   // ← Changed to VoidCallback?
  final Widget? suffixIcon;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted != null ? (_) => onFieldSubmitted!() : null,
          style: TextStyle(fontSize: isSmallScreen ? 15 : 16, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontSize: isSmallScreen ? 14 : 15),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

// Modern Sign In Button
class _ModernSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ModernSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: isSmallScreen ? 56 : 60,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)])
              : const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}