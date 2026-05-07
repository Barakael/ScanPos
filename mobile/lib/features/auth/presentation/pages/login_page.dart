import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/utils/validators.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
// Warm minimal palette: cream whites, charcoal ink, terracotta accent

class _T {
  // Backgrounds
  static const bgPage   = Color(0xFFFAF9F7);   // warm off-white
  static const bgPanel  = Color(0xFFFFFFFF);   // pure white card
  static const bgInput  = Color(0xFFF4F3F1);   // warm light grey input

  // Brand / Accent — purple
  static const accent   = Color(0xFF7C3AED);   // purple primary
  static const accentLt = Color(0xFFA78BFA);   // lighter purple
  static const accentBg = Color(0xFFF3F0FF);   // tint for focus rings

  // Text
  static const ink      = Color(0xFF1A1714);   // near-black
  static const inkMid   = Color(0xFF5C5550);   // medium grey-brown
  static const inkSoft  = Color(0xFF9A9390);   // soft placeholder

  // Structure
  static const border   = Color(0xFFE8E5E1);   // warm border
  static const divider  = Color(0xFFEFECE8);   // subtle divider
  static const error    = Color(0xFFC0392B);   // clear red error

  // Gradient — subtle warm paper gradient for page bg
  static const Gradient pageBg = LinearGradient(
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
    colors: [Color(0xFFFDFBF9), Color(0xFFF5F3EF)],
  );

  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF1A1714).withOpacity(0.06),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF1A1714).withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

// ── Page ──────────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    Future.microtask(() { if (mounted) _fadeCtrl.forward(); });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      context.read<AuthBloc>().add(AuthLoginRequested(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      ));
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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _T.bgPage,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            setState(() => _isLoading = state is AuthLoading);
            if (state is AuthAuthenticated) {
              context.go(RouteNames.dashboard);
            } else if (state is AuthUnauthenticated) {
              _showError(context, 'Invalid email or password.');
            } else if (state is AuthError) {
              _showError(context, state.message);
            } else if (state is AuthPhoneVerificationRequired) {
              _showError(context, 'Phone verification unavailable at this time.');
            }
          },
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Stack(
              children: [
                // Warm page gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(gradient: _T.pageBg),
                  ),
                ),

                // Subtle top accent bar
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 3,
                    color: _T.accent,
                  ),
                ),

<<<<<<< HEAD
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
=======
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: size.height - 80),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 48),

                            // ── Logo + wordmark ─────────────────────────
                            Row(
                              children: [
                                _LogoBadge(),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tera POS',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: _T.ink,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Text(
                                      'Business Management',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: _T.inkSoft,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 52),

                            // ── Headline ─────────────────────────────────
                            Text(
                              'Welcome back',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: _T.ink,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to manage your business',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                color: _T.inkMid,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ── Card ─────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: _T.bgPanel,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _T.cardShadow,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // Email
                                    _FieldLabel('Email address'),
                                    const SizedBox(height: 8),
                                    _InputField(
                                      controller: _emailController,
                                      hint:       'you@company.com',
                                      icon:       Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator:  Validators.email,
                                      textInputAction: TextInputAction.next,
                                    ),

                                    const SizedBox(height: 20),

                                    // Password
                                    _FieldLabel('Password'),
                                    const SizedBox(height: 8),
                                    _InputField(
                                      controller: _passwordController,
                                      hint:       'Enter your password',
                                      icon:       Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      validator:  Validators.password,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: _submit,
                                      suffixIcon: _VisibilityToggle(
                                        obscure:  _obscurePassword,
                                        onTap:    () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _T.accent,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 28),

                                    // Sign in button
                                    _SubmitButton(
                                      label:     'Sign In',
                                      isLoading: _isLoading,
                                      onPressed: _submit,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Register link
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: _T.inkMid,
                                  ),
                                  children: [
                                    const TextSpan(text: "Don't have an account? "),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => GoRouter.of(context).go('/register'),
                                        child: Text(
                                          'Create one',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: _T.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Footer
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Center(
                                child: Text(
                                  '© 2026 Tera POS',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: _T.inkSoft,
                                  ),
                                ),
                              ),
                            ),
                          ],
>>>>>>> 640d20165eaea23c4eb2a9a51e596a96aebbeb38
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
    );
  }

  void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _T.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        elevation: 0,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _T.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/logo/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _T.inkMid,
        ),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String   hint;
  final IconData icon;
  final bool     obscureText;
  final String?  Function(String?)? validator;
  final TextInputType   keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback?  onFieldSubmitted;
  final Widget?        suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.validator,
    this.keyboardType    = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    return TextFormField(
      controller:       controller,
      obscureText:      obscureText,
      validator:        validator,
      keyboardType:     keyboardType,
      textInputAction:  textInputAction,
      onFieldSubmitted: onFieldSubmitted != null ? (_) => onFieldSubmitted!() : null,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        color: _T.ink,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: GoogleFonts.dmSans(color: _T.inkSoft, fontSize: 14.5),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: _T.inkSoft, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        filled:    true,
        fillColor: _T.bgInput,
        contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
>>>>>>> 640d20165eaea23c4eb2a9a51e596a96aebbeb38
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _T.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _T.accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _T.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _T.error, width: 1.8),
        ),
        errorStyle: GoogleFonts.dmSans(color: _T.error, fontSize: 12),
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool       obscure;
  final VoidCallback onTap;
  const _VisibilityToggle({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _T.inkSoft,
          size: 18,
        ),
      );
}

class _SubmitButton extends StatelessWidget {
  final String       label;
  final bool         isLoading;
  final VoidCallback onPressed;
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.accent,
          disabledBackgroundColor: _T.border,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
>>>>>>> 640d20165eaea23c4eb2a9a51e596a96aebbeb38
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}