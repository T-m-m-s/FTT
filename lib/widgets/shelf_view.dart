import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../theme/app_colors.dart';

class ShelfView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<LibraryEntry> entries;
  final Function(LibraryEntry) onEntryTap;

  const ShelfView({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.entries,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Group items into rows of up to 5 items per shelf
    const itemsPerRow = 5;
    final List<List<LibraryEntry>> rows = [];
    for (var i = 0; i < entries.length; i += itemsPerRow) {
      final end = (i + itemsPerRow < entries.length) ? i + itemsPerRow : entries.length;
      rows.add(entries.sublist(i, end));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const Spacer(),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // Render each shelf row
          ...rows.map((rowItems) => _buildShelfRow(context, rowItems)),
        ],
      ),
    );
  }

  Widget _buildShelfRow(BuildContext context, List<LibraryEntry> rowItems) {
    return Column(
      children: [
        // Game cases sitting upright on the shelf
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              if (index < rowItems.length) {
                final entry = rowItems[index];
                return _buildBookCover(context, entry);
              } else {
                // Empty placeholder space
                return const SizedBox(width: 52, height: 78);
              }
            }),
          ),
        ),

        // The 3D Shelf Plank
        const ShelfPlank(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBookCover(BuildContext context, LibraryEntry entry) {
    return GestureDetector(
      onTap: () => onEntryTap(entry),
      child: Hero(
        tag: 'shelf_${title}_${entry.id}',
        child: Container(
          width: 54,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  entry.mediaItem.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceElevated,
                    child: Center(
                      child: Text(
                        entry.mediaItem.title[0],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Subtle case plastic reflection overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 35,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Left spine shadow for 3D box feel
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 3,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 3D Skeuomorphic Physical Shelf Plank
class ShelfPlank extends StatelessWidget {
  const ShelfPlank({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shelf Top Surface / Reflection
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.shelfWoodHighlight,
                AppColors.shelfWoodBody,
              ],
            ),
          ),
        ),
        // Shelf Front Lip / Bevel
        Container(
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.shelfWoodBody,
                AppColors.shelfWoodUnderside,
              ],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
          ),
        ),
        // Shelf Drop Shadow underneath
        Container(
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.shelfShadow.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
