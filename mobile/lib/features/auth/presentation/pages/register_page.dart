import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();

  bool _obscurePassword = true;
  String? _selectedRole;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 80), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _submit() {
    HapticFeedback.lightImpact();
    if (_formKey.currentState!.validate()) {
      String? companyId;
      if (_selectedRole == 'Business Owner') {
        companyId = _companyController.text.trim().isEmpty
            ? 'default-company-id'
            : _companyController.text.trim();
      }
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text,
              companyId: companyId,
              roleName: _selectedRole,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        body: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              // Glow blobs
              Positioned(
                top: -80,
                right: -80,
                child: _blob(const Color(0xFF3B82F6).withOpacity(0.18), 320),
              ),
              Positioned(
                bottom: -60,
                left: -60,
                child: _blob(const Color(0xFF06B6D4).withOpacity(0.12), 260),
              ),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // ── Top bar ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Row(
                            children: [
                              // Back button
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.12)),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Logo
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF0EA5E9)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.asset(
                                    'assets/images/logo/logo.png',
                                    fit: BoxFit.contain,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.point_of_sale_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tera POS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Create your account',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Headline ──────────────────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Get started',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in your details to create an account',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Card ──────────────────────────────────────
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32)),
                            ),
                            child: BlocListener<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state
                                    is AuthPhoneVerificationRequired) {
                                  _showSnack(
                                    context,
                                    'Phone verification is not available.',
                                  );
                                  context.go(RouteNames.login);
                                } else if (state is AuthError) {
                                  _showSnack(context, state.message);
                                } else if (state is AuthAuthenticated) {
                                  context.go(RouteNames.dashboard);
                                }
                              },
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 28, 24, 32),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Account Type
                                      _SectionHeader(
                                          label: 'Account Type',
                                          icon: Icons
                                              .manage_accounts_outlined),
                                      const SizedBox(height: 10),
                                      _StyledDropdown(
                                        value: _selectedRole,
                                        hint: 'Select account type',
                                        items: const [
                                          'Personal',
                                          'Business Owner'
                                        ],
                                        onChanged: (val) => setState(
                                            () => _selectedRole = val),
                                      ),

                                      // Company (conditional)
                                      if (_selectedRole ==
                                          'Business Owner') ...[
                                        const SizedBox(height: 20),
                                        _SectionHeader(
                                            label: 'Company',
                                            icon: Icons
                                                .storefront_outlined),
                                        const SizedBox(height: 10),
                                        _buildField(
                                          controller: _companyController,
                                          hint: 'Company name',
                                          icon:
                                              Icons.storefront_outlined,
                                          validator: Validators.required,
                                        ),
                                      ],

                                      const SizedBox(height: 20),

                                      // Personal Details
                                      _SectionHeader(
                                          label: 'Personal Details',
                                          icon: Icons
                                              .person_outline_rounded),
                                      const SizedBox(height: 10),

                                      // Name row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildField(
                                              controller:
                                                  _firstNameController,
                                              hint: 'First name',
                                              icon: Icons
                                                  .person_outline_rounded,
                                              validator:
                                                  Validators.required,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildField(
                                              controller:
                                                  _lastNameController,
                                              hint: 'Last name',
                                              icon: Icons
                                                  .person_outline_rounded,
                                              validator:
                                                  Validators.required,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      _buildField(
                                        controller: _emailController,
                                        hint: 'Email address',
                                        icon: Icons.alternate_email_rounded,
                                        validator: Validators.email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),

                                      const SizedBox(height: 14),

                                      _buildField(
                                        controller: _phoneController,
                                        hint: 'Phone number',
                                        icon: Icons.phone_outlined,
                                        validator: Validators.phone,
                                        keyboardType: TextInputType.phone,
                                      ),

                                      const SizedBox(height: 14),

                                      // Password
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        validator: Validators.password,
                                        onFieldSubmitted: (_) => _submit(),
                                        style: _fieldTextStyle,
                                        decoration: _fieldDeco(
                                          hint: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                          suffix: GestureDetector(
                                            onTap: () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
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

                                      const SizedBox(height: 28),

                                      // Submit
                                      BlocBuilder<AuthBloc, AuthState>(
                                        builder: (context, state) =>
                                            SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: state is AuthLoading
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFFCBD5E1),
                                                        Color(0xFFCBD5E1)
                                                      ],
                                                    )
                                                  : const LinearGradient(
                                                      begin:
                                                          Alignment.topLeft,
                                                      end: Alignment
                                                          .bottomRight,
                                                      colors: [
                                                        Color(0xFF2563EB),
                                                        Color(0xFF0EA5E9),
                                                      ],
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow:
                                                  state is AuthLoading
                                                      ? []
                                                      : [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFF3B82F6)
                                                                .withOpacity(
                                                                    0.35),
                                                            blurRadius: 20,
                                                            offset:
                                                                const Offset(
                                                                    0, 6),
                                                          ),
                                                        ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: state is AuthLoading
                                                  ? null
                                                  : _submit,
                                              style:
                                                  ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor:
                                                    Colors.transparent,
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14),
                                                ),
                                              ),
                                              child: state is AuthLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.2,
                                                      ),
                                                    )
                                                  : const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          'Create Account',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700,
                                                            fontSize: 16,
                                                            letterSpacing:
                                                                0.3,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          color:
                                                              Colors.white,
                                                          size: 18,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Sign in link
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Already have an account?',
                                            style: TextStyle(
                                              color: const Color(0xFF64748B),
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => context.pop(),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Sign in',
                                              style: TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
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
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );

  static const TextStyle _fieldTextStyle = TextStyle(
    fontSize: 15,
    color: Color(0xFF0F172A),
    fontWeight: FontWeight.w500,
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: _fieldTextStyle,
      decoration: _fieldDeco(hint: hint, icon: icon, suffix: suffix),
    );
  }

  InputDecoration _fieldDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
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
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }
}

// ── Section header widget ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Styled dropdown ───────────────────────────────────────────────────────────

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint,
              style: const TextStyle(
                  color: Color(0xFFCBD5E1), fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF94A3B8)),
          items: items
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A))),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}