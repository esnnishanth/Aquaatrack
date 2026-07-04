import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class OwnerSignupScreen extends StatefulWidget {
  const OwnerSignupScreen({super.key});
  static const routeName = '/owner-signup';

  @override
  State<OwnerSignupScreen> createState() => _OwnerSignupScreenState();
}

enum _SignupStep { details, otp, password }

class _OwnerSignupScreenState extends State<OwnerSignupScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _floatController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  String _email = '';
  String _name = '';
  String _phone = '';
  _SignupStep _step = _SignupStep.details;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pwController.dispose();
    _confirmController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  // ── Step 1 ──
  Future<void> _submitDetails() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Enter your name'); return; }
    if (email.isEmpty || !email.contains('@')) { setState(() => _error = 'Enter a valid email'); return; }
    if (phone.isEmpty || !RegExp(r'^\d{10}$').hasMatch(phone)) { setState(() => _error = 'Enter a valid 10-digit phone number'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final exists = await api.ownerExists(email);
      if (!mounted) return;
      if (exists) {
        setState(() { _error = 'This email already has an account. Please login.'; _loading = false; });
        return;
      }
      _name = name;
      _email = email;
      _phone = phone;
      await api.sendOtpEmail(_email);
      setState(() { _step = _SignupStep.otp; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  // ── Step 2 ──
  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) { setState(() => _error = 'Enter the complete 6-digit code'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<ApiService>().verifyEmailOtp(_email, code);
      if (!mounted) return;
      setState(() { _step = _SignupStep.password; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _resendOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<ApiService>().sendOtpEmail(_email);
      if (!mounted) return;
      for (final c in _otpControllers) { c.clear(); }
      _otpFocusNodes[0].requestFocus();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  // ── Step 3 ──
  Future<void> _createAccount() async {
    final pw = _pwController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pw.isEmpty) { setState(() => _error = 'Enter a password'); return; }
    if (pw.length < 6) { setState(() => _error = 'Password must be at least 6 characters'); return; }
    if (pw != confirm) { setState(() => _error = 'Passwords do not match'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().signUpWithEmail(name: _name, email: _email, phone: _phone, password: pw);
      await context.read<AuthService>().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
      );
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _back() {
    if (_step == _SignupStep.otp) {
      setState(() { _step = _SignupStep.details; _error = null; });
    } else if (_step == _SignupStep.password) {
      setState(() { _step = _SignupStep.otp; _error = null; });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.light(), child: Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) => CustomPaint(
                painter: _SignupMeshPainter(shift: _floatController.value),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, _) => Opacity(
                  opacity: _fadeController.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _fadeController.value)),
                    child: Column(
                      children: [
                        // ── Header with back ──
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: IconButton(
                                onPressed: _back,
                                icon: Icon(Icons.arrow_back_rounded, color: const Color(0xFF1A2332), size: 20),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _step == _SignupStep.details ? 'Create Account'
                                  : _step == _SignupStep.otp ? 'Verify Email'
                                  : 'Set Password',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1A2332),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Glass card ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: AppTheme.glassDecoration(borderRadius: 24, opacity: 0.65, brightness: Brightness.light),
                              child: Column(
                                children: [
                                  _buildStepIndicator(),
                                  const SizedBox(height: 28),
                                  _buildStepIcon(),
                                  const SizedBox(height: 20),
                                  _buildTitle(),
                                  const SizedBox(height: 8),
                                  _buildSubtitle(),
                                  const SizedBox(height: 28),
                                  _buildBody(),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _buildError(),
                        ],

                        const SizedBox(height: 32),
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
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(0, 'Details'),
        _line(),
        _dot(1, 'OTP'),
        _line(),
        _dot(2, 'Password'),
      ],
    );
  }

  Widget _dot(int index, String label) {
    final active = _step.index >= index;
    final done = _step.index > index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30, height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done || active ? AppTheme.primaryGradient : null,
            color: done || active ? null : Colors.white.withValues(alpha: 0.5),
            border: Border.all(
              color: done || active ? Colors.transparent : const Color(0xFFE5E7EB),
            ),
            boxShadow: active ? [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
            ] : [],
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF6B7280),
                      fontSize: 12, fontWeight: FontWeight.w700,
                    )),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          fontSize: 10,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? AppTheme.primary : const Color(0xFF6B7280),
        )),
      ],
    );
  }

  Widget _line() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40, height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: _step.index >= 1 ? AppTheme.primaryGradient : null,
        color: _step.index >= 1 ? null : Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildStepIcon() {
    IconData icon;
    if (_step == _SignupStep.details) { icon = Icons.person_outline_rounded; }
    else if (_step == _SignupStep.otp) { icon = Icons.mail_outline_rounded; }
    else { icon = Icons.lock_outline_rounded; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildTitle() {
    String title;
    if (_step == _SignupStep.details) { title = 'Enter your details'; }
    else if (_step == _SignupStep.otp) { title = 'Verify your email'; }
    else { title = 'Set your password'; }
    return Text(title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1A2332)));
  }

  Widget _buildSubtitle() {
    String subtitle;
    if (_step == _SignupStep.details) {
      subtitle = 'We\'ll check if you already have an account';
    } else if (_step == _SignupStep.otp) {
      subtitle = 'Enter the 6-digit code sent to\n$_email';
    } else {
      subtitle = 'Create a password to secure your account';
    }
    return Text(subtitle,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280), height: 1.5));
  }

  Widget _buildBody() {
    switch (_step) {
      case _SignupStep.details: return _buildDetailsStep();
      case _SignupStep.otp: return _buildOtpStep();
      case _SignupStep.password: return _buildPasswordStep();
    }
  }

  Future<void> _signupWithGoogle() async {
    final phone = await _showPhoneDialog();
    if (phone == null) return;
    _phone = phone;
    setState(() { _loading = true; _error = null; });
    try {
      final account = await context.read<AuthService>().pickGoogleAccount();
      if (account == null) { setState(() => _loading = false); return; }
      _name = account.name;
      _email = account.email;
      final api = context.read<ApiService>();
      final exists = await api.ownerExists(_email);
      if (!mounted) return;
      if (exists) {
        setState(() { _error = 'This email already has an account. Please login.'; _loading = false; });
        return;
      }
      final existingPhone = await api.ownerExistsByPhone(phone);
      if (existingPhone) {
        if (!mounted) return;
        setState(() { _error = 'This phone number already has an account.'; _loading = false; });
        return;
      }
      await api.sendOtpEmail(_email);
      if (!mounted) return;
      setState(() { _step = _SignupStep.otp; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<String?> _showPhoneDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            hintText: '10-digit phone number',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final p = controller.text.trim();
              if (p.isEmpty || !RegExp(r'^\d{10}$').hasMatch(p)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid 10-digit phone number')),
                );
                return;
              }
              Navigator.of(ctx).pop(p);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Widget _buildDetailsStep() {
    return Column(
      children: [
        // ── Google button ──
        Container(
          width: double.infinity, height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _signupWithGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 22, color: Color(0xFF4285F4)),
            label: Text('SIGN UP WITH GOOGLE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A2332),
              backgroundColor: Colors.transparent,
              side: BorderSide.none,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── OR divider ──
        Row(
          children: [
            Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR', style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
          ],
        ),
        const SizedBox(height: 20),

        _GlassField(controller: _nameController, hint: 'Full Name', icon: Icons.person_outline_rounded),
        const SizedBox(height: 14),
        _GlassField(controller: _emailController, hint: 'Email Address', icon: Icons.alternate_email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _GlassField(controller: _phoneController, hint: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 24),

        // ── Continue button ──
        Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _submitDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('CONTINUE'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 6.0;
            final fieldWidth = (constraints.maxWidth - gap * 5) / 6;
            return Row(
              children: List.generate(6, (i) {
                return Padding(
                  padding: EdgeInsets.only(left: i > 0 ? gap : 0),
                  child: SizedBox(
                    width: fieldWidth, height: 56,
                    child: _GlassOtpField(
                      controller: _otpControllers[i],
                      focusNode: _otpFocusNodes[i],
                      onChanged: (val) {
                        if (val.isNotEmpty && i < 5) { _otpFocusNodes[i + 1].requestFocus(); }
                        else if (val.isEmpty && i > 0) { _otpFocusNodes[i - 1].requestFocus(); }
                        if (i == 5 && val.isNotEmpty) { FocusScope.of(context).unfocus(); }
                      },
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: _loading ? null : _resendOtp,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Resend OTP', style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.7), fontSize: 13)),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('VERIFY'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        _GlassField(controller: _pwController, hint: 'Password', icon: Icons.lock_outline_rounded, obscure: true),
        const SizedBox(height: 14),
        _GlassField(controller: _confirmController, hint: 'Confirm Password', icon: Icons.lock_outline_rounded, obscure: true),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _createAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('CREATE ACCOUNT'),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.destructive.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.destructive.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppTheme.destructive, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.destructive, fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mesh painter ───────────────────────────────────────────────────────────
class _SignupMeshPainter extends CustomPainter {
  _SignupMeshPainter({required this.shift});
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    final c1 = AppTheme.meshColors[0].withValues(alpha: 0.12 + shift * 0.04);
    final c2 = AppTheme.meshColors[2].withValues(alpha: 0.10 + (1 - shift) * 0.04);
    final c3 = AppTheme.meshColors[3].withValues(alpha: 0.08 + shift * 0.03);
    paint.color = c1;
    canvas.drawCircle(Offset(size.width * 0.25 + shift * 15, size.height * 0.15), size.width * 0.4, paint);
    paint.color = c2;
    canvas.drawCircle(Offset(size.width * 0.75 - shift * 15, size.height * 0.4), size.width * 0.35, paint);
    paint.color = c3;
    canvas.drawCircle(Offset(size.width * 0.4 + shift * 10, size.height * 0.85), size.width * 0.3, paint);
  }

  @override
  bool shouldRepaint(_SignupMeshPainter old) => old.shift != shift;
}

// ── Glass text field ───────────────────────────────────────────────────────
class _GlassField extends StatefulWidget {
  const _GlassField({
    required this.controller, required this.hint,
    required this.icon, this.obscure = false, this.keyboardType,
  });

  final TextEditingController controller; final String hint;
  final IconData icon; final bool obscure; final TextInputType? keyboardType;

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  bool _focused = false;
  late final FocusNode _node;
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _node = FocusNode()..addListener(() => setState(() => _focused = _node.hasFocus));
    _hidden = widget.obscure;
  }

  @override
  void dispose() { _node.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: _focused
            ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _node,
        obscureText: widget.obscure ? _hidden : false,
        keyboardType: widget.keyboardType,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        style: GoogleFonts.inter(color: const Color(0xFF1A2332), fontSize: 14),
        cursorColor: AppTheme.primary,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
          prefixIcon: Icon(widget.icon, color: const Color(0xFF6B7280), size: 19),
          suffixIcon: widget.obscure
              ? IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF6B7280), size: 19),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Glass OTP field ────────────────────────────────────────────────────────
class _GlassOtpField extends StatelessWidget {
  const _GlassOtpField({
    required this.controller, required this.focusNode, required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 1,
      style: GoogleFonts.spaceGrotesk(color: const Color(0xFF1A2332), fontSize: 22, fontWeight: FontWeight.w700),
      cursorColor: AppTheme.primary,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
