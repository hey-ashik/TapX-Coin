import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/guest_confirm_modal.dart';
import '../widgets/otp_pin_input.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Staged Reveal Animations
  late Animation<double> _iconScaleAnim;
  late Animation<double> _iconOpacityAnim;
  late Animation<double> _titleOpacityAnim;
  late Animation<double> _titleSpacingAnim;
  late Animation<double> _taglineOpacityAnim;
  late Animation<Offset> _sheetSlideAnim;
  late Animation<double> _sheetOpacityAnim;
  late Animation<double> _topPositionShiftAnim;

  int _selectedSegment = 0; // 0 = Sign In, 1 = Register
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // OTP Verification state
  bool _isVerifyingOtp = false;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  int _resendTimerSeconds = 45;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. Icon Reveal (0% -> 35%)
    _iconScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _iconOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );

    // 2. "TAPX" Logo Reveal (25% -> 55%)
    _titleOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleSpacingAnim = Tween<double>(begin: 12.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // 3. "TAP • EARN • COMPETE" Tagline Reveal (45% -> 70%)
    _taglineOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.45, 0.70, curve: Curves.easeOut),
      ),
    );

    // 4. Logo shift upward slightly (60% -> 95%)
    _topPositionShiftAnim = Tween<double>(begin: 0.12, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.60, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    // 5. Auth Modal Slide-up from bottom (65% -> 100%)
    _sheetSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _sheetOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 0.90, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendTimerSeconds = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() => _resendTimerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleSubmit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (_selectedSegment == 0) {
      // 1. Sign In validation
      if (email.isEmpty || password.isEmpty) {
        AppToast.show(
          context,
          message: 'Please enter your email and password.',
          isError: true,
        );
        return;
      }

      final res = await auth.login(email, password);
      if (!mounted) return;

      if (res['success'] == true) {
        AppToast.show(
          context,
          message: 'Welcome back to TapX!',
          isError: false,
        );
      } else if (res['needs_verification'] == true) {
        AppToast.show(
          context,
          message: 'Please enter the 6-digit OTP code to verify your account.',
          isError: false,
        );
        _startResendCountdown();
        setState(() => _isVerifyingOtp = true);
        Future.delayed(const Duration(milliseconds: 250), () {
          _otpFocusNode.requestFocus();
        });
      } else {
        AppToast.show(
          context,
          message: res['message'] ?? 'Invalid email or password credentials.',
          isError: true,
        );
      }
    } else {
      // 2. Registration validation
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        AppToast.show(
          context,
          message: 'Please complete all registration fields.',
          isError: true,
        );
        return;
      }

      if (password.length < 6) {
        AppToast.show(
          context,
          message: 'Password must be at least 6 characters.',
          isError: true,
        );
        return;
      }

      final res = await auth.register(name: name, email: email, password: password);
      if (!mounted) return;

      if (res['success'] == true) {
        AppToast.show(
          context,
          message: 'Verification code sent to your email!',
          isError: false,
        );
        _startResendCountdown();
        setState(() => _isVerifyingOtp = true);
        Future.delayed(const Duration(milliseconds: 250), () {
          _otpFocusNode.requestFocus();
        });
      } else {
        AppToast.show(
          context,
          message: res['message'] ?? 'Registration failed. Please check your email.',
          isError: true,
        );
      }
    }
  }

  void _handleVerifyOtp() async {
    final auth = context.read<AuthProvider>();
    final code = _otpController.text.trim();

    if (code.length < 6) {
      AppToast.show(
        context,
        message: 'Please enter the complete 6-digit code.',
        isError: true,
      );
      return;
    }

    final res = await auth.verifyOtp(code);
    if (!mounted) return;

    if (res['success'] == true) {
      AppToast.show(
        context,
        message: 'Account verified! Welcome to TapX.',
        isError: false,
      );
    } else {
      AppToast.show(
        context,
        message: res['message'] ?? 'Invalid OTP code. Please enter the correct code.',
        isError: true,
      );
    }
  }

  void _handleGuestClick() {
    GuestConfirmModal.show(
      context,
      onConfirmGuest: () {
        final auth = context.read<AuthProvider>();
        auth.loginAsGuest();
        AppToast.show(
          context,
          message: 'Signed in as Guest Tapper!',
          isError: false,
        );
      },
      onSwitchToRegister: () {
        setState(() {
          _selectedSegment = 1;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_animController.isAnimating) {
            _animController.forward(from: 0.9);
          }
        },
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    // Brand Header Area (flexible top)
                    Expanded(
                      flex: _isVerifyingOtp ? 2 : 3,
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: EdgeInsets.only(
                          top: constraints.maxHeight *
                              _topPositionShiftAnim.value,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glowing radial aura
                            Opacity(
                              opacity: _iconOpacityAnim.value * 0.8,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                      blurRadius: 70,
                                      spreadRadius: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 1. Fingerprint Icon
                                Opacity(
                                  opacity: _iconOpacityAnim.value,
                                  child: Transform.scale(
                                    scale: _iconScaleAnim.value,
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.surfaceCard,
                                        border: Border.all(
                                          color: AppColors.borderStrong,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                            blurRadius: 30,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 2. "TapX" Logo Title
                                Opacity(
                                  opacity: _titleOpacityAnim.value,
                                  child: Text(
                                    'TapX',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(
                                          fontSize: 34,
                                          letterSpacing: _titleSpacingAnim.value,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // 3. Tagline
                                Opacity(
                                  opacity: _taglineOpacityAnim.value,
                                  child: Text(
                                    'TAP • EARN • ENJOY',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          letterSpacing: 3.0,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Auth Modal Sheet (Fitted, zero dead gap at bottom)
                    SlideTransition(
                      position: _sheetSlideAnim,
                      child: Opacity(
                        opacity: _sheetOpacityAnim.value,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            border: const Border(
                              top: BorderSide(
                                color: AppColors.borderSubtle,
                                width: 1.2,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.9),
                                blurRadius: 40,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                              child: _isVerifyingOtp
                                  ? _buildOtpVerificationView(auth)
                                  : _buildAuthFormView(auth),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 1. Main Auth Form View (Sign In & Register)
  Widget _buildAuthFormView(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Drag handle
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 18),

        // Segment switch (Sign In / Register)
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSegment = 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: _selectedSegment == 0
                          ? AppColors.surfaceCard
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedSegment == 0
                            ? AppColors.borderStrong
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _selectedSegment == 0
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSegment = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: _selectedSegment == 1
                          ? AppColors.surfaceCard
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedSegment == 1
                            ? AppColors.borderStrong
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _selectedSegment == 1
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Name Field (Only in Register mode)
        if (_selectedSegment == 1) ...[
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.primary),
            decoration: const InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline,
                  color: AppColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Email Input
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.primary),
          decoration: const InputDecoration(
            hintText: 'Email Address',
            prefixIcon: Icon(Icons.mail_outline,
                color: AppColors.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 12),

        // Password Input
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppColors.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.ctaText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.ctaText),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedSegment == 0 ? 'Continue' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Guest Mode Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: auth.isLoading ? null : _handleGuestClick,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: const Text(
              'Guest User',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. OTP Code Verification View
  Widget _buildOtpVerificationView(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Back Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                _otpFocusNode.unfocus();
                setState(() => _isVerifyingOtp = false);
              },
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Text(
                'Step 2 of 2',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Shield Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceSubtle,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Verify Your Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the 6-digit code sent to your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Interactive 6-digit OTP Box Input with auto-advance and mobile keyboard trigger
        OtpPinInput(
          length: 6,
          onChanged: (code) {
            _otpController.text = code;
          },
          onCompleted: (code) {
            _otpController.text = code;
            _handleVerifyOtp();
          },
        ),
        const SizedBox(height: 14),

        // Resend code countdown
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _resendTimerSeconds > 0
                  ? 'Resend code in 00:${_resendTimerSeconds.toString().padLeft(2, '0')}'
                  : 'Didn\'t receive code? ',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            if (_resendTimerSeconds == 0)
              InkWell(
                onTap: () {
                  auth.resendOtp();
                  _startResendCountdown();
                  AppToast.show(context, message: 'New code sent to your email!');
                },
                child: const Text(
                  'Resend Now',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),

        // Verify & Launch Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.ctaText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.ctaText),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Verify & Launch TapX',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
