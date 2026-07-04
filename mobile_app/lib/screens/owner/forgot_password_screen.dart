import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _ResetStep { email, otp, newPassword }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _floatController;
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  String _email = '';
  _ResetStep _step = _ResetStep.email;

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
    _emailController.dispose();
    _pwController.dispose();
    _confirmController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().sendPasswordResetEmail(email);
      _email = email;
      if (!mounted) return;
      setState(() { _step = _ResetStep.otp; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _verifyOtp() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _error = 'Enter the complete 6-digit code');
      return;
    }
    setState(() { _step = _ResetStep.newPassword; _error = null; });
  }

  Future<void> _resetPassword() async {
    final pw = _pwController.text.trim();
    final confirm = _confirmController.text.trim();
    if (pw.isEmpty) { setState(() => _error = 'Enter a new password'); return; }
    if (pw.length < 6) { setState(() => _error = 'Password must be at least 6 characters'); return; }
    if (pw != confirm) { setState(() => _error = 'Passwords do not match'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final code = _otpControllers.map((c) => c.text).join();
      await context.read<AuthService>().resetPassword(email: _email, otp: code, newPassword: pw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _back() {
    if (_step == _ResetStep.otp) {
      setState(() { _step = _ResetStep.email; _error = null; });
    } else if (_step == _ResetStep.newPassword) {
      setState(() { _step = _ResetStep.otp; _error = null; });
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
                painter: _ForgotMeshPainter(shift: _floatController.value),
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
                        // ── Header ──
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
                              _step == _ResetStep.email ? 'Forgot Password'
                                  : _step == _ResetStep.otp ? 'Verify OTP'
                                  : 'Reset Password',
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
                                  // ── Step icon ──
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.primaryGradient,
                                      boxShadow: [
                                        BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Icon(
                                      _step == _ResetStep.email
                                          ? Icons.mark_email_unread_outlined
                                          : _step == _ResetStep.otp
                                              ? Icons.pin_outlined
                                              : Icons.lock_outline_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Description ──
                                  Text(
                                    _step == _ResetStep.email
                                        ? 'Enter your email and we\'ll send you a reset code'
                                        : _step == _ResetStep.otp
                                            ? 'Enter the 6-digit code sent to\n$_email'
                                            : 'Enter your new password',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(0xFF6B7280),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  if (_step == _ResetStep.email) _buildEmailStep(),
                                  if (_step == _ResetStep.otp) _buildOtpStep(),
                                  if (_step == _ResetStep.newPassword) _buildPasswordStep(),
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

  Widget _buildEmailStep() {
    return Column(
      children: [
        _GlassField(controller: _emailController, hint: 'Email address', icon: Icons.alternate_email),
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
            onPressed: _loading ? null : _sendReset,
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
                : Text('SEND RESET CODE'),
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
                : Text('VERIFY OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        _GlassField(controller: _pwController, hint: 'New password', icon: Icons.lock_outline_rounded, obscure: true),
        const SizedBox(height: 14),
        _GlassField(controller: _confirmController, hint: 'Confirm new password', icon: Icons.lock_outline_rounded, obscure: true),
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
            onPressed: _loading ? null : _resetPassword,
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
                : Text('RESET PASSWORD'),
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
class _ForgotMeshPainter extends CustomPainter {
  _ForgotMeshPainter({required this.shift});
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    final c1 = AppTheme.meshColors[1].withValues(alpha: 0.10 + shift * 0.04);
    final c2 = AppTheme.meshColors[3].withValues(alpha: 0.08 + (1 - shift) * 0.04);
    final c3 = AppTheme.meshColors[0].withValues(alpha: 0.07 + shift * 0.03);
    paint.color = c1;
    canvas.drawCircle(Offset(size.width * 0.3 + shift * 15, size.height * 0.2), size.width * 0.35, paint);
    paint.color = c2;
    canvas.drawCircle(Offset(size.width * 0.7 - shift * 15, size.height * 0.5), size.width * 0.3, paint);
    paint.color = c3;
    canvas.drawCircle(Offset(size.width * 0.5 + shift * 10, size.height * 0.8), size.width * 0.35, paint);
  }

  @override
  bool shouldRepaint(_ForgotMeshPainter old) => old.shift != shift;
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
