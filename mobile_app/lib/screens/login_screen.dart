import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/manager_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/loading_view.dart';
import '../theme/app_theme.dart';
import 'manager/manager_dashboard_screen.dart';
import 'owner/owner_dashboard_screen.dart';
import 'owner/owner_signup_screen.dart';
import 'owner/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _role = 'manager';
  String _loginId = '';
  String _password = '';
  bool _isLoading = true;
  bool _authLoading = false;
  String? _error;
  bool _keepSignedIn = true;

  late final AnimationController _fadeController;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _floatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine));
    _loadManagers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadManagers() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
    }
  }

  Future<void> _managerLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _authLoading = true; _error = null; });

    final vehicleNum = _loginId.trim().toUpperCase();

    try {
      final api = context.read<ApiService>();
      final manager = await api.findManagerByVehicleNumber(vehicleNum);
      if (manager == null) {
        setState(() { _error = 'No manager found with this vehicle number'; _authLoading = false; });
        return;
      }
      if (manager.password != _password) {
        setState(() { _error = 'Invalid password'; _authLoading = false; });
        return;
      }
      if (manager.locked || manager.frozen) {
        final reason = manager.statusReason.isNotEmpty ? '\nReason: ${manager.statusReason}' : '';
        setState(() { _error = 'Your manager account is locked. Contact admin.' + reason; _authLoading = false; });
        return;
      }
      if (_keepSignedIn) {
        await StorageService.saveManagerId(manager.id);
      }
      await context.read<ManagerProvider>().fetchManager(manager.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(ManagerDashboardScreen.routeName);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _authLoading = false;
      });
    }
  }

  Future<void> _ownerLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _authLoading = true; _error = null; });

    try {
      await StorageService.saveKeepOwnerSignedIn(_keepSignedIn);
      await context.read<AuthService>().signInWithEmail(_loginId, _password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _authLoading = false;
      });
    }
  }

  Future<void> _ownerGoogleLogin() async {
    setState(() { _authLoading = true; _error = null; });
    try {
      final auth = context.read<AuthService>();
      final api = context.read<ApiService>();

      final account = await auth.pickGoogleAccount();
      if (account == null) { setState(() => _authLoading = false); return; }

      final exists = await api.ownerExists(account.email);
      if (!mounted) return;

      if (!exists) {
        await auth.googleSignOut();
        setState(() { _error = 'No account exists with ${account.email}. Please sign up first.'; _authLoading = false; });
        return;
      }

      await StorageService.saveKeepOwnerSignedIn(_keepSignedIn);
      await auth.signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _authLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Theme(data: AppTheme.light(), child: Scaffold(body: LoadingView(message: 'Loading...')));
    }

    return Theme(data: AppTheme.light(), child: Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // ── Animated gradient background ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) => CustomPaint(
                painter: _MeshGradientPainter(shift: _floatController.value),
              ),
            ),
          ),

          // ── Frosted backdrop overlay ──
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, _) => Opacity(
                    opacity: _fadeController.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _fadeController.value)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // ── Logo area ──
                          AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (context, _) => Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withValues(alpha: 0.4),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 42),
                                  ),
                                  const SizedBox(height: 20),
                                  Text('AQUA TRACK',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A2332),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      'BORE DRILLING MANAGEMENT',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accent,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── Role cards ──
                          Row(
                            children: [
                              Expanded(child: _RoleCard(
                                icon: Icons.work_outline_rounded,
                                label: 'Manager',
                                active: _role == 'manager',
                                onTap: () => setState(() { _role = 'manager'; _error = null; }),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _RoleCard(
                                icon: Icons.verified_outlined,
                                label: 'Owner',
                                active: _role == 'owner',
                                onTap: () => setState(() { _role = 'owner'; _error = null; }),
                              )),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Glass login card ──
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                decoration: AppTheme.glassDecoration(borderRadius: 20, opacity: 0.65, brightness: Brightness.light),
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _Field(
                                        hint: _role == 'manager' ? 'Vehicle Number' : 'Email',
                                        icon: _role == 'manager' ? Icons.local_shipping : Icons.alternate_email,
                                        keyboardType: _role == 'manager' ? TextInputType.text : TextInputType.emailAddress,
                                        textCapitalization: _role == 'manager' ? TextCapitalization.characters : TextCapitalization.none,
                                        onSaved: (v) => _loginId = v?.trim() ?? '',
                                        validator: (v) => (v == null || v.trim().isEmpty) ? (_role == 'manager' ? 'Enter vehicle number' : 'Enter email') : null,
                                      ),
                                      const SizedBox(height: 14),
                                      _Field(
                                        hint: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: true,
                                        onSaved: (v) => _password = v?.trim() ?? '',
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter password' : null,
                                      ),

                                      if (_role == 'owner') ...[
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () => Navigator.of(context).pushNamed(ForgotPasswordScreen.routeName),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text('Forgot Password?', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 22, width: 22,
                                            child: Checkbox(
                                              value: _keepSignedIn,
                                              onChanged: (v) => setState(() => _keepSignedIn = v ?? false),
                                              activeColor: AppTheme.primary,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => setState(() => _keepSignedIn = !_keepSignedIn),
                                            child: Text('Keep me signed in', style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13)),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 18),

                                      // ── Sign In button ──
                                      Container(
                                        width: double.infinity, height: 52,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primary.withValues(alpha: 0.35),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _authLoading ? null : (_role == 'manager' ? _managerLogin : _ownerLogin),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: Colors.transparent,
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                          ),
                                          child: _authLoading
                                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                              : Text('SIGN IN'),
                                        ),
                                      ),

                                      if (_role == 'owner') ...[
                                        const SizedBox(height: 14),

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
                                            onPressed: _authLoading ? null : _ownerGoogleLogin,
                                            icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: Color(0xFF4285F4)),
                                            label: Text('SIGN IN WITH GOOGLE'),
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

                                        const SizedBox(height: 14),
                                        GestureDetector(
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const OwnerSignupScreen()),
                                          ),
                                          child: RichText(
                                            text: TextSpan(
                                              text: "Don't have an account? ",
                                              style: TextStyle(color: const Color(0xFF6B7280), fontSize: 13),
                                              children: [
                                                TextSpan(text: 'Sign Up', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ── Error ──
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Container(
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
                          ],

                          const SizedBox(height: 32),
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
    );
  }
}

// ── Mesh gradient painter ──────────────────────────────────────────────────
class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({required this.shift});
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final c1 = AppTheme.meshColors[0].withValues(alpha: 0.15 + shift * 0.05);
    final c2 = AppTheme.meshColors[1].withValues(alpha: 0.12 + (1 - shift) * 0.05);
    final c3 = AppTheme.meshColors[2].withValues(alpha: 0.10 + shift * 0.04);

    paint.color = c1;
    canvas.drawCircle(Offset(size.width * 0.2 + shift * 20, size.height * 0.2), size.width * 0.4, paint);
    paint.color = c2;
    canvas.drawCircle(Offset(size.width * 0.8 - shift * 20, size.height * 0.3), size.width * 0.35, paint);
    paint.color = c3;
    canvas.drawCircle(Offset(size.width * 0.5 + shift * 15, size.height * 0.8), size.width * 0.3, paint);
  }

  @override
  bool shouldRepaint(_MeshGradientPainter old) => old.shift != shift;
}

// ── Role Card ──────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon; final String label; final bool active; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppTheme.primary : const Color(0xFFE5E7EB),
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: active ? AppTheme.primary : const Color(0xFF6B7280)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppTheme.primary : const Color(0xFF6B7280),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Text Field ─────────────────────────────────────────────────────────────
class _Field extends StatefulWidget {
  const _Field({
    required this.hint, required this.icon,
    this.obscure = false, this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onSaved, this.validator,
  });

  final String hint; final IconData icon; final bool obscure;
  final TextInputType? keyboardType; final TextCapitalization textCapitalization;
  final FormFieldSetter<String>? onSaved; final FormFieldValidator<String>? validator;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
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
      child: TextFormField(
        focusNode: _node,
        obscureText: widget.obscure ? _hidden : false,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        onSaved: widget.onSaved,
        validator: widget.validator,
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
                  icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF6B7280), size: 19),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.destructive, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.destructive, width: 1.5),
          ),
          errorStyle: TextStyle(color: AppTheme.destructive, fontSize: 12),
        ),
      ),
    );
  }
}
