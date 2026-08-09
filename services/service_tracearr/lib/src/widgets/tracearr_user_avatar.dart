import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A widget displaying a user profile photo or a deterministic, vibrant
/// fallback avatar based on username.
class TracearrUserAvatar extends StatelessWidget {
  const TracearrUserAvatar({
    required this.username,
    this.avatarUrl,
    this.radius = 20,
    this.fontSize,
    super.key,
  });

  final String username;
  final String? avatarUrl;
  final double radius;
  final double? fontSize;

  static const List<Color> _avatarColors = <Color>[
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF64748B), // Slate
  ];

  Color _getDeterministicColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    final int hash = name.codeUnits.fold(0, (int prev, int elem) => prev + elem);
    return _avatarColors[hash.abs() % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final String trimmed = username.trim();
    final String initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    final Color bgColor = _getDeterministicColor(trimmed);
    final double computedFontSize = fontSize ?? (radius * 0.85);

    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                _buildFallback(initial, bgColor, computedFontSize),
          ),
        ),
      );
    }

    return _buildFallback(initial, bgColor, computedFontSize);
  }

  Widget _buildFallback(String initial, Color bgColor, double effectiveFontSize) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: effectiveFontSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
