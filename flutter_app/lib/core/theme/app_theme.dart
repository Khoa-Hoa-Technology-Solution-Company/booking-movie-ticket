import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =============================================
/// CINEMA TICKET APP - CENTRALIZED DESIGN TOKENS
/// Based on design-system/MASTER.md
/// Obsidian Cinema Theme
/// =============================================

class AppColors {
  // === CORE PALETTE ===
  static const Color background    = Color(0xFF0F0F1A); // Obsidian Black
  static const Color surface       = Color(0xFF16162A); // Deep Indigo Surface
  static const Color surfaceHigh   = Color(0xFF1E1B4B); // Elevated surface
  static const Color border        = Color(0x15FFFFFF); // Translucent White border

  // === BRAND COLORS ===
  static const Color primary       = Color(0xFFC084FC); // Neon Lavender
  static const Color primaryDim    = Color(0x26C084FC); // Neon Lavender 15%
  static const Color secondary     = Color(0xFF8B5CF6); // Royal Violet
  static const Color accent        = Color(0xFFF59E0B); // Golden Amber (VIP/Stars)
  static const Color success       = Color(0xFF10B981); // Emerald Green (selected seat)
  static const Color danger        = Color(0xFFEF4444); // Crimson Red (couple seat/error)

  // === TEXT COLORS ===
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3CC); // white70 equivalent
  static const Color textMuted     = Color(0xFF6B6B8A); // white38 equivalent

  // === GRADIENTS ===
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1B4B), Color(0xFF0F0F1A)],
  );

  static const LinearGradient heroBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC084FC), Color(0xFF8B5CF6)],
  );

  static const LinearGradient posterScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xFF0F0F1A)],
    stops: [0.3, 1.0],
  );
}

class AppRadius {
  static const double seat      = 8.0;
  static const double card      = 16.0;
  static const double cardLarge = 20.0;
  static const double button    = 16.0;
  static const double sheet     = 24.0;
  static const double badge     = 8.0;
}

class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double base = 16.0;
  static const double lg   = 20.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;
}

class AppTextStyles {
  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, height: 1.2,
  );

  static TextStyle get titleMedium => GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.3,
  );

  static TextStyle get titleSmall => GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.normal,
    color: AppColors.textSecondary, height: 1.5,
  );

  static TextStyle get bodyBold => GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get caption => GoogleFonts.robotoMono(
    fontSize: 12, fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static TextStyle get seatLabel => GoogleFonts.robotoMono(
    fontSize: 10, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get price => GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:    AppColors.primary,
      secondary:  AppColors.secondary,
      surface:    AppColors.surface,
      error:      AppColors.danger,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleSmall,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: GoogleFonts.outfit(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ==========================================
// SHARED WIDGETS (tiny reusable components)
// ==========================================

/// Neon purple badge label (e.g. age rating, genre chip)
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const AppBadge({
    super.key,
    required this.label,
    this.color = AppColors.primaryDim,
    this.textColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}

/// Shimmer skeleton loader box
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 8});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFF1A1A2E),
                Color(0xFF2A2A4A),
                Color(0xFF1A1A2E),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Gradient primary button with ripple and disabled state
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: disabled ? null : AppColors.primaryGradient,
          color: disabled ? AppColors.textMuted : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: disabled ? null : [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: disabled ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Center(
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.black, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
