import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/library_entry.dart';
import '../models/media_type.dart';
import '../models/play_session.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/format_bottom_sheet.dart';

class MediaDetailScreen extends StatefulWidget {
  final LibraryEntry entry;

  const MediaDetailScreen({super.key, required this.entry});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late LibraryEntry _entry;
  final db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  void _showFormatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormatBottomSheet(
        entry: _entry,
        onSave: (updated) {
          setState(() => _entry = updated);
          db.addOrUpdateEntry(_entry);
        },
      ),
    );
  }

  void _quickLogCinemaSession({required int duration, required String note}) {
    final session = PlaySession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      mediaId: _entry.mediaId,
      mediaTitle: _entry.mediaItem.title,
      mediaPoster: _entry.mediaItem.posterUrl,
      mediaType: _entry.mediaItem.mediaType,
      date: DateTime.now(),
      durationMinutes: duration,
      platform: _entry.platform,
      notes: note,
    );
    db.addSession(session);
    setState(() {
      _entry.timeSpentMinutes += duration;
      _entry.lastActivity = DateTime.now();
      if (_entry.status == LibraryStatus.backlog || _entry.status == LibraryStatus.wishlist) {
        _entry.status = LibraryStatus.playing;
      }
    });
    db.addOrUpdateEntry(_entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $note ($duration min) for ${_entry.mediaItem.title}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAddSessionDialog() {
    final isTv = _entry.mediaItem.mediaType == MediaType.tvShow;
    final isMovie = _entry.mediaItem.mediaType == MediaType.movie;
    final defaultRuntime = _entry.mediaItem.runtimeMinutes;
    int minutes = (defaultRuntime != null && defaultRuntime > 0)
        ? defaultRuntime
        : (isTv ? 45 : (isMovie ? 120 : 60));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Log ${_entry.mediaItem.mediaType == MediaType.game ? "Play" : "Watch"} Session',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Duration: ${minutes ~/ 60}h ${minutes % 60}m',
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: minutes.toDouble().clamp(15.0, 360.0),
                min: 15,
                max: 360,
                divisions: 23,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceCard,
                onChanged: (val) => setDlgState(() => minutes = val.toInt()),
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: isTv
                      ? 'Episode notes (e.g. S01E03)...'
                      : (isMovie ? 'Movie watch notes...' : 'Notes for this session...'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final session = PlaySession(
                  id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
                  mediaId: _entry.mediaId,
                  mediaTitle: _entry.mediaItem.title,
                  mediaPoster: _entry.mediaItem.posterUrl,
                  mediaType: _entry.mediaItem.mediaType,
                  date: DateTime.now(),
                  durationMinutes: minutes,
                  platform: _entry.platform,
                  notes: notesController.text,
                );
                db.addSession(session);
                setState(() {
                  _entry.timeSpentMinutes += minutes;
                  _entry.lastActivity = DateTime.now();
                  if (_entry.status == LibraryStatus.backlog || _entry.status == LibraryStatus.wishlist) {
                    _entry.status = LibraryStatus.playing;
                  }
                });
                db.addOrUpdateEntry(_entry);
                Navigator.pop(ctx);
              },
              child: const Text('Log Session', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _entry.mediaItem;
    final isGame = item.mediaType == MediaType.game;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Hero App Bar
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.backdropUrl.isNotEmpty ? item.backdropUrl : item.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surfaceElevated),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.8),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 175,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(item.posterUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status Pill
                  _buildStatusDropdown(),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.releaseDateFormatted}  •  ${item.genres.join(', ')}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Playthrough Card (Matching Screenshot 1 Screen 4)
                  _buildPlaythroughCard(isGame),
                  const SizedBox(height: 16),

                  // Platforms & Formats Card (Matching Screenshot 1 Screen 5)
                  _buildPlatformCard(),
                  const SizedBox(height: 16),

                  // User Rating Section
                  _buildRatingSection(),
                  const SizedBox(height: 16),

                  // Synopsis
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Synopsis',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.synopsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LibraryStatus>(
          value: _entry.status,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryLight, size: 20),
          isDense: true,
          items: LibraryStatus.values.map((s) {
            return DropdownMenuItem<LibraryStatus>(
              value: s,
              child: Text(
                s.label,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (newStatus) {
            if (newStatus != null) {
              setState(() => _entry.status = newStatus);
              db.updateStatus(_entry.mediaId, newStatus);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlaythroughCard(bool isGame) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGame ? 'Playthroughs' : 'Watch History',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isGame) ...[
                    OutlinedButton(
                      onPressed: () {
                        final isTv = _entry.mediaItem.mediaType == MediaType.tvShow;
                        final duration = (_entry.mediaItem.runtimeMinutes != null && _entry.mediaItem.runtimeMinutes! > 0)
                            ? _entry.mediaItem.runtimeMinutes!
                            : (isTv ? 45 : 120);
                        _quickLogCinemaSession(
                          duration: duration,
                          note: isTv ? '+1 Episode' : 'Full Movie',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(color: AppColors.primaryLight),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        _entry.mediaItem.mediaType == MediaType.tvShow ? '+1 Ep' : '+ Watched',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _showAddSessionDialog,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Log Session', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular progress indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (_entry.progressPercent / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                    ),
                    Center(
                      child: Text(
                        '${_entry.progressPercent.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time: ${_entry.formattedTimeSpent}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Status: ${_entry.status.shortLabel}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _entry.lastActivity != null
                          ? 'Last: ${DateFormat("MMM d, y").format(_entry.lastActivity!)}'
                          : 'No sessions logged',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard() {
    return GestureDetector(
      onTap: _showFormatSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.devices_rounded, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platforms & Formats',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_entry.platform}  •  ${_entry.format}  •  ${_entry.isOwned ? "Owned" : "Unowned"}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = _entry.userRating ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Rating',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                rating > 0 ? '${rating.toStringAsFixed(1)} / 10' : 'Unrated',
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: rating,
            min: 0.0,
            max: 10.0,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceElevated,
            onChanged: (val) {
              setState(() => _entry.userRating = val);
              db.updateRating(_entry.mediaId, val);
            },
          ),
        ],
      ),
    );
  }
}
