import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/showtime.dart';
import '../../models/cinema.dart';
import '../../services/location_service.dart';
import '../core/theme/app_theme.dart';

/// A premium, interactive seat widget that renders itself according to 
/// its type (Standard, VIP, Couple) and state (Selected, Booked, Held, Maintenance, Available).
class SeatWidget extends StatelessWidget {
  final Seat seat;
  final bool isSelected;
  final VoidCallback onTap;

  const SeatWidget({
    super.key,
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBooked = seat.status == SeatStatus.booked;
    final bool isMaintenance = seat.status == SeatStatus.maintenance || !seat.isActive;
    final bool isHeld = seat.status == SeatStatus.held;

    Color seatColor = Colors.white24;
    IconData? icon;

    if (isBooked) {
      seatColor = const Color(0xFF1E1E2E); // Dark charcoal
      icon = Icons.close_rounded; // Dấu X cho ghế đã đặt
    } else if (isHeld) {
      seatColor = Colors.orange;
      icon = Icons.person_outline;
    } else if (isMaintenance) {
      seatColor = Colors.grey.shade800;
      icon = Icons.construction; // Wrench/hammer icon
    } else if (isSelected) {
      seatColor = const Color(0xFF4ADE80); // Emerald Green
      icon = Icons.check_rounded; // Dấu check cho ghế đang chọn
    } else {
      // Color according to SeatType
      if (seat.type == SeatType.vip) {
        seatColor = const Color(0xFFF97316); // Amber/Orange
      } else if (seat.type == SeatType.couple) {
        seatColor = const Color(0xFFEF4444); // Crimson Red
        icon = Icons.favorite_rounded; // Trái tim cho ghế đôi
      } else {
        seatColor = Colors.white54; // Standard
      }
    }

    final Widget innerContent = Center(
      child: icon != null
          ? Icon(
              icon,
              color: isBooked ? Colors.white24 : (isSelected ? Colors.black : Colors.white70),
              size: 14,
            )
          : Text(
              '${seat.number}',
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
    );

    Widget seatBox;
    if (seat.type == SeatType.vip && !isBooked && !isMaintenance && !isHeld && !isSelected) {
      // Viền đôi cho ghế VIP khi chưa chọn
      seatBox = Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: seatColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: seatColor, width: 1.5),
            borderRadius: BorderRadius.circular(5),
          ),
          child: innerContent,
        ),
      );
    } else {
      seatBox = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: (isSelected || isBooked || isMaintenance || isHeld) ? seatColor : Colors.transparent,
          border: Border.all(
            color: seatColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: innerContent,
      );
    }

    return GestureDetector(
      onTap: (isBooked || isMaintenance) ? null : onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: seatBox,
      ),
    );
  }
}

/// A custom, easy-to-tap counter selector complying with 44pt touch targets.
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (quantity > 0) ...[
          _buildActionButton(
            icon: Icons.remove_circle_outline,
            onPressed: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '$quantity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
        _buildActionButton(
          icon: Icons.add_circle,
          onPressed: onIncrement,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 44, // Minimum touch target size
          height: 44, // Minimum touch target size
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: const Color(0xFFC084FC), // Neon Lavender
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// A food card featuring dark container colors, network images, and 
/// monospaced prices.
class FoodCard extends StatelessWidget {
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool isCombo;

  const FoodCard({
    super.key,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.isCombo = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Image with network loading states
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 68,
                height: 68,
                color: Colors.white.withOpacity(0.04),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFC084FC),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            isCombo ? Icons.fastfood : Icons.local_cafe,
                            color: const Color(0xFFC084FC),
                            size: 28,
                          );
                        },
                      )
                    : Icon(
                        isCombo ? Icons.fastfood : Icons.local_cafe,
                        color: const Color(0xFFC084FC),
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Price with monospaced digit style
                  Text(
                    formatter.format(price),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontFamilyFallback: ['Courier New', 'Roboto Mono'],
                      color: Color(0xFFC084FC),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Quantity selector
            QuantitySelector(
              quantity: quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }
}

/// A premium, overflow-safe cinema card that displays cinema name, address,
/// optional distance result, and trailing city badge.
class CinemaListTile extends StatelessWidget {
  final Cinema cinema;
  final CinemaDistanceResult? distanceResult;
  final VoidCallback? onTap;

  const CinemaListTile({
    super.key,
    required this.cinema,
    this.distanceResult,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon rạp
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.movie_creation_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              // Thông tin rạp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cinema.name, style: AppTextStyles.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(cinema.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                    if (distanceResult != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 11),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${distanceResult!.distanceText} • ${distanceResult!.durationText}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge thành phố
              AppBadge(label: cinema.city, color: Colors.white10, textColor: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// A grouped card representing a cinema and its corresponding showtime slots/hour chips.
class CinemaShowtimeCard extends StatelessWidget {
  final Cinema cinema;
  final List<Showtime> showtimes;
  final CinemaDistanceResult? distanceResult;
  final ValueChanged<Showtime> onShowtimeTap;

  const CinemaShowtimeCard({
    super.key,
    required this.cinema,
    required this.showtimes,
    this.distanceResult,
    required this.onShowtimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cinema header with distance info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cinema.name, style: AppTextStyles.bodyBold),
                    const SizedBox(height: 2),
                    Text(cinema.address, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (distanceResult != null)
                GestureDetector(
                  onTap: (cinema.latitude != null && cinema.longitude != null)
                      ? () async {
                          final url = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${cinema.latitude},${cinema.longitude}',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            await launchUrl(url, mode: LaunchMode.platformDefault);
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceResult!.distanceText} • ${distanceResult!.durationText}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                AppBadge(label: cinema.city, color: Colors.white10, textColor: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),

          // Showtime hour chips under this cinema
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: showtimes.map((st) {
              final timeStr = DateFormat('HH:mm').format(st.startTime);
              return GestureDetector(
                onTap: () => onShowtimeTap(st),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        st.room?.roomType ?? '2D',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatter.format(st.price),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A premium, customizable list tile displaying flat showtime information.
class ShowtimeListTile extends StatelessWidget {
  final Showtime showtime;
  final VoidCallback onTap;

  const ShowtimeListTile({
    super.key,
    required this.showtime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final movie = showtime.movie;
    final room = showtime.room;
    final cinema = showtime.cinema;
    final price = showtime.price;
    final startTime = showtime.startTime;

    final timeStr = DateFormat('HH:mm').format(startTime);
    final dateStr = DateFormat('dd/MM/yyyy').format(startTime);
    final movieTitle = movie?.title ?? 'Phim';
    final posterUrl = movie?.posterUrl;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 70,
              color: AppColors.border,
              child: posterUrl != null && posterUrl.isNotEmpty
                  ? Image.network(posterUrl, fit: BoxFit.cover)
                  : Icon(Icons.movie, color: AppColors.textMuted),
            ),
          ),
          title: Text(
            movieTitle,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              '${cinema?.name ?? 'Rạp'} • ${room?.name ?? 'Phòng'} (${room?.roomType ?? '2D'})\nNgày $dateStr • Giá vé: ${formatter.format(price)}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          trailing: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
