import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/steam_service.dart';
import '../theme/app_colors.dart';

class SteamSyncScreen extends StatefulWidget {
  const SteamSyncScreen({super.key});

  @override
  State<SteamSyncScreen> createState() => _SteamSyncScreenState();
}

class _SteamSyncScreenState extends State<SteamSyncScreen> {
  final db = DatabaseService();
  final _usernameController = TextEditingController(text: '76561199041297020');
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _syncProfile({bool isDemo = false}) async {
    final input = _usernameController.text.trim();
    final customApiKey = _apiKeyController.text.trim();

    if (input.isEmpty && !isDemo) {
      setState(() {
        _errorMessage = 'Please enter your SteamID64 or profile link.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = isDemo
          ? await SteamService.generateDemoProfile()
          : await SteamService.fetchProfile(
              usernameOrId: input,
              apiKey: customApiKey.isNotEmpty ? customApiKey : null,
            );

      setState(() => _isLoading = false);

      if (profile != null) {
        db.setSteamProfile(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Connected as ${profile.personaName} (${profile.games.length} games imported)!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.statusCompleted,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage =
              'Could not find a public Steam profile for "$input".\n\nNote: Steam account login names are private and cannot be looked up. Please enter your 17-digit Steam ID (e.g. 76561199041297020) or your Steam profile URL.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  Future<void> _syncFromLocal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await SteamService.syncFromLocalSteamClient();
      setState(() => _isLoading = false);

      if (profile != null && profile.games.isNotEmpty) {
        db.setSteamProfile(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Synced ${profile.games.length} games directly from local Steam client!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.statusCompleted,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Could not read local Steam library. Make sure Steam is installed and you are logged in.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error syncing local Steam: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: db,
      builder: (context, _) {
        final currentProfile = db.steamProfile;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: const Text(
              'Steam Integration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF171A21), Color(0xFF1B2838), Color(0xFF2A475E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B2838).withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF66C0F4).withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF66C0F4), size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Steam Cloud Library',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sync playtime hours & games seamlessly without passwords.',
                            style: TextStyle(
                              color: Color(0xFFC7D5E0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Local Steam Client Detected Card (if available)
              if (SteamService.hasLocalSteamClient()) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3C55), Color(0xFF142434)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF66C0F4).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66C0F4).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.desktop_windows_rounded, color: Color(0xFF66C0F4), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Local Steam Client Detected!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'No API key or password needed',
                                  style: TextStyle(color: Color(0xFF66C0F4), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'FTT found your local Steam installation on this machine. You can sync your complete library (80+ games) with exact playtime instantly without needing any Web API key!',
                        style: TextStyle(color: Color(0xFFC7D5E0), fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _syncFromLocal(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF66C0F4),
                            foregroundColor: const Color(0xFF0F141C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.flash_on_rounded, size: 20),
                          label: const Text(
                            'One-Tap Sync from Local Steam (80+ Games)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Safe & Secure Note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '100% Safe: Only your public profile ID or link is needed. Your Steam password is never asked and never needed.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Connected Profile Card (if active)
              if (currentProfile != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.statusCompleted.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              currentProfile.avatarUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 54,
                                height: 54,
                                color: AppColors.surfaceElevated,
                                child: const Icon(Icons.person, color: Colors.white54),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentProfile.personaName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusCompleted.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Connected',
                                        style: TextStyle(
                                          color: AppColors.statusCompleted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentProfile.games.length} games  •  ${currentProfile.totalHoursPlayed}h logged',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.borderSubtle, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : () => _syncProfile(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.borderSubtle),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight, size: 18),
                              label: const Text(
                                'Re-sync',
                                style: TextStyle(color: AppColors.primaryLight, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                db.clearSteamProfile();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Steam profile disconnected.')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 18),
                              label: const Text(
                                'Disconnect',
                                style: TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info banner regarding Valve's API key requirement for full library
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF66C0F4), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Public Activity Sync Active',
                            style: TextStyle(color: Color(0xFF66C0F4), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Games shown below were synced from your public reviews and badges. To sync your full 65-game Steam library, Valve requires a free Steam Web API Key (expand Advanced below).',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '💡 Tip: In Steam Privacy Settings, ensure "Always keep my total playtime private" is unchecked so hours are visible.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Steam ID / Profile URL Input Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Steam ID or Profile URL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Paste your profile URL or your 17-digit SteamID (not your account login)',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. 76561199041297020 or steamcommunity.com/profiles/...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        prefixIcon: const Icon(Icons.person_search_rounded, color: AppColors.textMuted, size: 20),
                        suffixIcon: _usernameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  _usernameController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Primary Connect Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _syncProfile(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                        label: Text(
                          _isLoading ? 'Syncing...' : 'Connect & Sync Steam',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Demo Test Button
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : () => _syncProfile(isDemo: true),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.bolt_rounded, color: Color(0xFF66C0F4), size: 18),
                        label: const Text(
                          'Try Instant Demo Profile',
                          style: TextStyle(color: Color(0xFF66C0F4), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Collapsible Advanced API Key Section
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: _showAdvanced,
                    onExpansionChanged: (val) => setState(() => _showAdvanced = val),
                    iconColor: AppColors.textMuted,
                    collapsedIconColor: AppColors.textMuted,
                    title: const Text(
                      'Advanced: Free Steam Web API Key (Optional)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Enables full 100% library sync for all games in your account',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            TextField(
                              controller: _apiKeyController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter 32-character Steam Web API Key',
                                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                prefixIcon: const Icon(Icons.key_rounded, color: AppColors.textMuted, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'How to get it in 10 seconds:\n1. Open steamcommunity.com/dev/apikey in browser\n2. In Domain Name, type "localhost" and click Register\n3. Paste the key here and tap Connect.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Synced Games Preview List
              if (currentProfile != null && currentProfile.games.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Synced Steam Games',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${currentProfile.games.length} total',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...currentProfile.games.map(
                  (g) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            g.headerUrl,
                            width: 72,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 72,
                              height: 36,
                              color: AppColors.surfaceElevated,
                              child: const Icon(Icons.gamepad, color: Colors.white38, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.name,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (g.playtime2WeeksMinutes > 0)
                                Text(
                                  '${(g.playtime2WeeksMinutes / 60).toStringAsFixed(1)}h past 2 weeks',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${g.totalHours}h',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
