import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/animated_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e), // Dark navy blue
              Color(0xFF0d47a1), // Medium blue
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // App Logo and Title
                    _buildHeader(),

                    const SizedBox(height: 48),

                    // Login/Register Form
                    _buildForm(authProvider),

                    const SizedBox(height: 24),

                    // Error Message
                    if (authProvider.errorMessage != null)
                      _buildErrorMessage(authProvider.errorMessage!),

                    const SizedBox(height: 24),

                    // Submit Button
                    _buildSubmitButton(authProvider),

                    const SizedBox(height: 16),

                    // Toggle Login/Register
                    _buildToggleButton(),

                    const SizedBox(height: 32),

                    // Demo Credentials
                    _buildDemoCredentials(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // OPTIRVA Logo - Professional animated design
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: const _OptirvaLogo(),
        ),

        const SizedBox(height: 20),

        // App Title - OPTIRVA
        const Text(
          'OPTIRVA',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle - Dairy Group Communications
        const Text(
          'Dairy Group Communications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFFFFD700), // Gold color
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name (only for register)
          if (!_isLoginMode) ...[
            AnimatedFormField(
              label: AppStrings.fullName,
              prefixIcon: Icons.person,
              controller: _nameController,
              validator: (value) {
                if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Email
          AnimatedFormField(
            label: AppStrings.email,
            prefixIcon: Icons.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Password
          AnimatedFormField(
            label: AppStrings.password,
            prefixIcon: Icons.lock,
            controller: _passwordController,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isLoginMode && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          // Confirm Password (only for register)
          if (!_isLoginMode) ...[
            const SizedBox(height: 20),
            AnimatedFormField(
              label: AppStrings.confirmPassword,
              prefixIcon: Icons.lock_outline,
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (!_isLoginMode && value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthProvider authProvider) {
    return AnimatedButton(
      text: _isLoginMode ? AppStrings.signIn : AppStrings.signUp,
      onPressed: authProvider.isLoading ? null : _handleSubmit,
      isLoading: authProvider.isLoading,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      padding: const EdgeInsets.symmetric(vertical: 18),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLoginMode = !_isLoginMode;
          _formKey.currentState?.reset();
          context.read<AuthProvider>().clearError();
        });
      },
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          children: [
            TextSpan(
              text: _isLoginMode
                  ? AppStrings.dontHaveAccount
                  : AppStrings.alreadyHaveAccount,
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: _isLoginMode ? AppStrings.signUp : AppStrings.signIn,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoCredentials() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Demo Credentials',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'You can create a new account or use these demo credentials:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email: demo@machine-manager.com',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Password: demo123',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  _emailController.text = 'demo@machine-manager.com';
                  _passwordController.text = 'demo123';
                },
                child: const Text(
                  'Fill Form',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isLoginMode) {
      success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
      );
    }

    if (success && mounted) {
      // Navigation will be handled automatically by AuthWrapper
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLoginMode ? 'Welcome back!' : 'Account created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

// OPTIRVA Logo Widget with Professional Animated Design
class _OptirvaLogo extends StatefulWidget {
  const _OptirvaLogo();

  @override
  State<_OptirvaLogo> createState() => _OptirvaLogoState();
}

class _OptirvaLogoState extends State<_OptirvaLogo> with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _lineController;

  late Animation<double> _orbitRotation;
  late Animation<double> _pulseRadius1;
  late Animation<double> _pulseOpacity1;
  late Animation<double> _pulseRadius2;
  late Animation<double> _pulseOpacity2;

  @override
  void initState() {
    super.initState();

    // Orbital rotation (20s)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _orbitRotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(_orbitController);

    // First pulse wave (3s) - gold
    _pulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _pulseRadius1 = Tween<double>(begin: 28, end: 48).animate(_pulseController1);
    _pulseOpacity1 = Tween<double>(begin: 0.7, end: 0).animate(_pulseController1);

    // Second pulse wave (2.5s) - blue
    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _pulseRadius2 = Tween<double>(begin: 28, end: 42).animate(_pulseController2);
    _pulseOpacity2 = Tween<double>(begin: 0.5, end: 0).animate(_pulseController2);

    // Line pulse animation (2s)
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController1.dispose();
    _pulseController2.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbitController, _pulseController1, _pulseController2, _lineController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _OptirvaLogoPainter(
            orbitRotation: _orbitRotation.value,
            pulseRadius1: _pulseRadius1.value,
            pulseOpacity1: _pulseOpacity1.value,
            pulseRadius2: _pulseRadius2.value,
            pulseOpacity2: _pulseOpacity2.value,
            linePhase: _lineController.value,
          ),
          size: const Size(120, 120),
        );
      },
    );
  }
}

// Custom Painter for OPTIRVA Logo
class _OptirvaLogoPainter extends CustomPainter {
  final double orbitRotation;
  final double pulseRadius1;
  final double pulseOpacity1;
  final double pulseRadius2;
  final double pulseOpacity2;
  final double linePhase;

  _OptirvaLogoPainter({
    required this.orbitRotation,
    required this.pulseRadius1,
    required this.pulseOpacity1,
    required this.pulseRadius2,
    required this.pulseOpacity2,
    required this.linePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final earthRadius = size.width * 0.233; // 28 pixels at 120px width

    // Draw Earth shadow with colored tint
    final shadowPaint = Paint()
      ..color = const Color(0xFF01579B).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(2, 3), earthRadius, shadowPaint);

    // Draw Earth globe - Vibrant Cyan to Deep Blue gradient
    final earthGradient = RadialGradient(
      center: const Alignment(-0.35, -0.35), // Light source from top-left
      colors: [
        const Color(0xFF00E5FF), // Vibrant cyan highlight
        const Color(0xFF00B8D4), // Light cyan-blue
        const Color(0xFF0091EA), // Medium blue
        const Color(0xFF01579B), // Deep blue shadow
      ],
      stops: const [0.0, 0.25, 0.6, 1.0],
    );
    final earthPaint = Paint()
      ..shader = earthGradient.createShader(Rect.fromCircle(center: center, radius: earthRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, earthRadius, earthPaint);

    // Draw rim glow - Vibrant cyan glow
    final rimPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, earthRadius, rimPaint);

    // Add enhanced glossy highlight overlay
    final highlightGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        Colors.white.withOpacity(0.9),
        const Color(0xFFE1F5FE).withOpacity(0.4),
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.3, 1.0],
    );
    final highlightPaint = Paint()
      ..shader = highlightGradient.createShader(Rect.fromCircle(center: center, radius: earthRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, earthRadius, highlightPaint);

    // Draw stylized continents - Vibrant Emerald Green
    final continentPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;

    final continentStroke = Paint()
      ..color = const Color(0xFF00C853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // North America
    final naRect = Rect.fromCenter(center: center.translate(-earthRadius * 0.3, -earthRadius * 0.4), width: 12, height: 18);
    canvas.drawOval(naRect, continentPaint);
    canvas.drawOval(naRect, continentStroke);

    // Europe/Africa
    final eaRect = Rect.fromCenter(center: center.translate(earthRadius * 0.1, -earthRadius * 0.2), width: 14, height: 22);
    canvas.drawOval(eaRect, continentPaint);
    canvas.drawOval(eaRect, continentStroke);

    // Asia
    final asiaRect = Rect.fromCenter(center: center.translate(earthRadius * 0.4, -earthRadius * 0.3), width: 16, height: 16);
    canvas.drawOval(asiaRect, continentPaint);
    canvas.drawOval(asiaRect, continentStroke);

    // South America
    final saRect = Rect.fromCenter(center: center.translate(-earthRadius * 0.2, earthRadius * 0.4), width: 10, height: 16);
    canvas.drawOval(saRect, continentPaint);
    canvas.drawOval(saRect, continentStroke);

    // Draw grid lines - Glowing cyan lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE1F5FE).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Horizontal lines (latitude)
    for (int i = -2; i <= 2; i++) {
      final y = center.dy + (i * earthRadius * 0.4);
      final width = earthRadius * 1.8 * (1 - (i.abs() * 0.25));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, y), width: width, height: earthRadius * 0.3),
        gridPaint,
      );
    }

    // Vertical lines (longitude)
    for (int i = -2; i <= 2; i++) {
      final x = center.dx + (i * earthRadius * 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, center.dy), width: earthRadius * 0.3, height: earthRadius * 2),
        gridPaint,
      );
    }

    // Draw network nodes with glow effect
    final nodePositions = [
      const Offset(0, -1), // Top
      const Offset(0.7, -0.7), // Top right
      const Offset(1, 0), // Right
      const Offset(0.7, 0.7), // Bottom right
      const Offset(0, 1), // Bottom
      const Offset(-0.7, 0.7), // Bottom left
      const Offset(-1, 0), // Left
      const Offset(-0.7, -0.7), // Top left
    ];

    final nodeRadius = size.width * 0.48;

    // Multi-color 3D gradients for nodes
    final goldGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFFFFEB3B), const Color(0xFFFFC107), const Color(0xFFFF6F00)],
      stops: const [0.0, 0.5, 1.0],
    );

    final emeraldGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFF69F0AE), const Color(0xFF00E676), const Color(0xFF00C853)],
      stops: const [0.0, 0.5, 1.0],
    );

    final purpleGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFFE040FB), const Color(0xFFD500F9), const Color(0xFFAA00FF)],
      stops: const [0.0, 0.5, 1.0],
    );

    final orangeGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFFFFB74D), const Color(0xFFFF9800), const Color(0xFFE65100)],
      stops: const [0.0, 0.5, 1.0],
    );

    // Node gradients and colors arrays
    final nodeGradients = [goldGradient, emeraldGradient, purpleGradient, orangeGradient, goldGradient, emeraldGradient, purpleGradient, orangeGradient];
    final nodeColors = [const Color(0xFFFFC107), const Color(0xFF00E676), const Color(0xFFE040FB), const Color(0xFFFF9800), const Color(0xFFFFC107), const Color(0xFF00E676), const Color(0xFFE040FB), const Color(0xFFFF9800)];
    final nodeHighlightColors = [const Color(0xFFFFEB3B), const Color(0xFF69F0AE), const Color(0xFFE040FB), const Color(0xFFFFB74D), const Color(0xFFFFEB3B), const Color(0xFF69F0AE), const Color(0xFFE040FB), const Color(0xFFFFB74D)];
    final lineColors = [const Color(0xFFFF9800), const Color(0xFF00E676), const Color(0xFFE040FB), const Color(0xFFFF9800), const Color(0xFFFFC107), const Color(0xFF00E676), const Color(0xFFE040FB), const Color(0xFFFFC107)];

    for (int i = 0; i < nodePositions.length; i++) {
      final pos = nodePositions[i];
      final nodePos = center.translate(pos.dx * nodeRadius, pos.dy * nodeRadius);

      // Draw connection line with node-specific color
      final linePaint = Paint()
        ..color = lineColors[i].withOpacity(0.5 + (linePhase * 0.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final earthSurfacePos = center.translate(pos.dx * earthRadius, pos.dy * earthRadius);
      canvas.drawLine(nodePos, earthSurfacePos, linePaint);

      // Draw outer glow with node color
      final glowPaint = Paint()
        ..color = nodeColors[i].withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(nodePos, 6.0 * (1.0 + linePhase * 0.4), glowPaint);

      // Draw 3D node base
      final node3DPaint = Paint()
        ..shader = nodeGradients[i].createShader(Rect.fromCircle(center: nodePos, radius: 5))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodePos, 5, node3DPaint);

      // Draw bright highlight spot on node
      final nodeHighlightPaint = Paint()
        ..color = nodeHighlightColors[i]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodePos.translate(-1, -1), 2.5, nodeHighlightPaint);
    }

    // Draw rotating orbital ring - Vibrant cyan
    final orbitalPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(orbitRotation);

    // Draw elliptical orbit for 3D perspective
    final path = Path()
      ..addOval(Rect.fromCenter(
        center: Offset.zero,
        width: nodeRadius * 2.0,
        height: nodeRadius * 0.8,
      ));

    // Create dashed path effect
    final dashPath = Path();
    double distance = 0;
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final segment = pathMetric.extractPath(distance, distance + 5);
        dashPath.addPath(segment, Offset.zero);
        distance += 8;
      }
    }
    canvas.drawPath(dashPath, orbitalPaint);
    canvas.restore();

    // Draw multiple pulsing signal waves - Rainbow colors
    final wavePaint1 = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(pulseOpacity1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, pulseRadius1, wavePaint1);

    // Secondary wave - Vibrant cyan
    final wavePaint2 = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(pulseOpacity2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, pulseRadius2, wavePaint2);

    // Third wave - Purple (using linePhase for animation)
    final purpleOpacity = linePhase > 0.5 ? (1 - linePhase) : linePhase;
    final wavePaint3 = Paint()
      ..color = const Color(0xFFE040FB).withOpacity(purpleOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, earthRadius * (1.0 + (linePhase * 0.35)), wavePaint3);
  }

  @override
  bool shouldRepaint(_OptirvaLogoPainter oldDelegate) {
    return oldDelegate.orbitRotation != orbitRotation ||
        oldDelegate.pulseRadius1 != pulseRadius1 ||
        oldDelegate.pulseOpacity1 != pulseOpacity1 ||
        oldDelegate.pulseRadius2 != pulseRadius2 ||
        oldDelegate.pulseOpacity2 != pulseOpacity2 ||
        oldDelegate.linePhase != linePhase;
  }
}