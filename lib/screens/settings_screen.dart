import 'package:flutter/material.dart';
import '../models/media_type.dart';
import '../services/anime_tracker_service.dart';
import '../services/database_service.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
import 'steam_sync_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService db = DatabaseService();
  final AnimeTrackerService _animeService = AnimeTrackerService();

  bool _isMalLoading = false;
  bool _isAnilistLoading = false;
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  void _showConnectMalDialog() {
    final controller = TextEditingController(text: db.malUsername ?? '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.video_library_rounded, color: Color(0xFF2E51A2), size: 24),
              SizedBox(width: 10),
              Text('Connect MyAnimeList', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your public MyAnimeList username to sync your anime watch history, episodes and movie ratings.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Xinil, FrigoBar...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2E51A2), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = controller.text.trim();
                if (user.isEmpty) return;
                Navigator.pop(ctx);
                _syncMal(user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E51A2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sync MAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncMal(String username) async {
    setState(() => _isMalLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Syncing anime from MyAnimeList for "$username"...'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final count = await _animeService.syncMyAnimeList(username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced $count anime items from MyAnimeList!'),
          backgroundColor: AppColors.statusCompleted,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MAL Sync Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.statusAbandoned,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isMalLoading = false);
    }
  }

  void _showConnectAnilistDialog() {
    final controller = TextEditingController(text: db.anilistUsername ?? '');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF02A9FF), size: 24),
              SizedBox(width: 10),
              Text('Connect AniList', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your AniList username to import your tracked anime TV series and anime movies.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. your_anilist_name',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF02A9FF), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = controller.text.trim();
                if (user.isEmpty) return;
                Navigator.pop(ctx);
                _syncAnilist(user);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF02A9FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sync AniList', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncAnilist(String username) async {
    setState(() => _isAnilistLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Syncing anime from AniList for "$username"...'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );

    try {
      final count = await _animeService.syncAniList(username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced $count anime items from AniList!'),
          backgroundColor: AppColors.statusCompleted,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AniList Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.statusAbandoned,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnilistLoading = false);
    }
  }

  void _confirmDisconnect(String serviceName, VoidCallback onDisconnect) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Disconnect $serviceName?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to disconnect $serviceName? Items imported from this service will be removed from your library.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDisconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Disconnected $serviceName.'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAbandoned,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmResetLibrary() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset entire library?', style: TextStyle(color: AppColors.statusAbandoned, fontWeight: FontWeight.bold)),
        content: const Text(
          'Warning: This action will permanently remove all games, movies, TV series and tracked session history from FreeTimeTracker.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              db.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All library data has been reset.'),
                  backgroundColor: AppColors.statusAbandoned,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAbandoned,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final steamProfile = db.steamProfile;
        final malUsername = db.malUsername;
        final anilistUsername = db.anilistUsername;

        final totalGames = db.library.where((e) => e.mediaItem.mediaType == MediaType.game).length;
        final totalCinema = db.library.where((e) => e.mediaItem.mediaType != MediaType.game).length;
        final totalSessions = db.sessions.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Settings & Connections',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Section 1: App & Updates
              _buildSectionHeader('App & System Updates', Icons.system_update_rounded),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: AppColors.primaryLight, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FreeTimeTracker (FTT)',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'v${UpdateService.appVersion} • Linux / Cross-platform',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => UpdateService.checkUpdateManually(context),
                          icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                          label: const Text('Check', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Gaming Connections
              _buildSectionHeader('Gaming Connections', Icons.sports_esports_rounded),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2838),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: steamProfile != null ? AppColors.statusCompleted : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Steam Profile',
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildBadge(
                                    label: steamProfile != null ? 'Connected' : 'Not Connected',
                                    color: steamProfile != null ? AppColors.statusCompleted : AppColors.textMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                steamProfile != null
                                    ? '${steamProfile.personaName} (${steamProfile.games.length} games synced)'
                                    : 'Import Steam games, playtime and activity history',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (steamProfile != null) ...[
                          OutlinedButton(
                            onPressed: () => _confirmDisconnect('Steam', () => db.clearSteamProfile()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusAbandoned,
                              side: const BorderSide(color: AppColors.statusAbandoned),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SteamSyncScreen()),
                          ),
                          icon: Icon(steamProfile != null ? Icons.sync : Icons.add_link_rounded, size: 14, color: Colors.white),
                          label: Text(steamProfile != null ? 'Re-Sync' : 'Connect Steam', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B2838),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Anime & Cinema Trackers
              _buildSectionHeader('Anime & Cinema Trackers', Icons.movie_filter_rounded),
              
              // MyAnimeList Card
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E51A2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: malUsername != null ? AppColors.statusCompleted : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(Icons.video_library_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'MyAnimeList (MAL)',
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildBadge(
                                    label: malUsername != null ? 'Connected' : 'Not Connected',
                                    color: malUsername != null ? AppColors.statusCompleted : AppColors.textMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                malUsername != null
                                    ? '$malUsername (${db.malAnimeCount} anime in library)'
                                    : 'Sync TV series, anime movies & watched episodes',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (malUsername != null) ...[
                          OutlinedButton(
                            onPressed: () => _confirmDisconnect('MyAnimeList', () => db.clearMalData()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusAbandoned,
                              side: const BorderSide(color: AppColors.statusAbandoned),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: _isMalLoading ? null : _showConnectMalDialog,
                          icon: _isMalLoading
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(malUsername != null ? Icons.sync : Icons.add_link_rounded, size: 14, color: Colors.white),
                          label: Text(
                            _isMalLoading ? 'Syncing...' : (malUsername != null ? 'Re-Sync' : 'Connect MAL'),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E51A2),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // AniList Card
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF02A9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: anilistUsername != null ? AppColors.statusCompleted : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'AniList',
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildBadge(
                                    label: anilistUsername != null ? 'Connected' : 'Not Connected',
                                    color: anilistUsername != null ? AppColors.statusCompleted : AppColors.textMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                anilistUsername != null
                                    ? '$anilistUsername (${db.anilistAnimeCount} anime in library)'
                                    : 'Connect with your public AniList account',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (anilistUsername != null) ...[
                          OutlinedButton(
                            onPressed: () => _confirmDisconnect('AniList', () => db.clearAnilistData()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusAbandoned,
                              side: const BorderSide(color: AppColors.statusAbandoned),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: _isAnilistLoading ? null : _showConnectAnilistDialog,
                          icon: _isAnilistLoading
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(anilistUsername != null ? Icons.sync : Icons.add_link_rounded, size: 14, color: Colors.white),
                          label: Text(
                            _isAnilistLoading ? 'Syncing...' : (anilistUsername != null ? 'Re-Sync' : 'Connect AniList'),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF02A9FF),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Custom Shelves & Categories
              _buildSectionHeader('Custom Shelves & Categories', Icons.view_agenda_rounded),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage custom categories and choose which ones display as shelves on your Home screen.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    for (final cat in db.categories) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${db.getEntriesForCategory(cat.id).length} items',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: cat.showOnHome,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) => db.toggleCategoryOnHome(cat.id),
                            ),
                            if (cat.id != 'cat_now_playing')
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                tooltip: 'Delete category',
                                onPressed: () => db.deleteCategory(cat.id),
                              ),
                          ],
                        ),
                      ),
                      if (cat != db.categories.last)
                        const Divider(color: AppColors.borderSubtle, height: 1),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newCategoryController,
                            decoration: InputDecoration(
                              hintText: 'Add new category...',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () {
                            final text = _newCategoryController.text.trim();
                            if (text.isNotEmpty) {
                              db.addCategory(text, showOnHome: true);
                              _newCategoryController.clear();
                            }
                          },
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 4: Storage & Data Management
              _buildSectionHeader('Storage & Library Management', Icons.storage_rounded),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPill('Games', '$totalGames', Icons.sports_esports_outlined),
                        _buildStatPill('Cinema & TV', '$totalCinema', Icons.movie_outlined),
                        _buildStatPill('Timeline Sessions', '$totalSessions', Icons.history_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderSubtle),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reset all library & timeline data',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        TextButton.icon(
                          onPressed: _confirmResetLibrary,
                          icon: const Icon(Icons.delete_forever_rounded, color: AppColors.statusAbandoned, size: 16),
                          label: const Text('Reset All', style: TextStyle(color: AppColors.statusAbandoned, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
