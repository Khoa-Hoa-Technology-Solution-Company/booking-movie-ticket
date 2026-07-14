import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/showtime.dart';

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
      icon = Icons.lock_outline;
    } else if (isHeld) {
      seatColor = Colors.orange.withOpacity(0.6);
      icon = Icons.person_outline;
    } else if (isMaintenance) {
      seatColor = Colors.grey.shade800;
      icon = Icons.construction; // Wrench/hammer icon
    } else if (isSelected) {
      seatColor = const Color(0xFF4ADE80); // Emerald Green
    } else {
      // Color according to SeatType
      if (seat.type == SeatType.vip) {
        seatColor = const Color(0xFFF97316); // Amber/Orange
      } else if (seat.type == SeatType.couple) {
        seatColor = const Color(0xFFEF4444); // Crimson Red
      } else {
        seatColor = Colors.white54; // Standard
      }
    }

    return GestureDetector(
      onTap: (isBooked || isMaintenance) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? seatColor : Colors.transparent,
          border: Border.all(
            color: seatColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: isBooked ? Colors.white24 : Colors.white70,
                  size: 16,
                )
              : Text(
                  '${seat.number}',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
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
              style: const TextStyle(
                color: Colors.white,
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
      color: const Color(0xFF16162A), // Dark surface color
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
                    style: const TextStyle(
                      color: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white54,
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
