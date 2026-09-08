import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_colors.dart';

class AppReleaseInfo {
  final String version;
  final String tagName;
  final String title;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String htmlUrl;
  final int apkSize;

  AppReleaseInfo({
    required this.version,
    required this.tagName,
    required this.title,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.htmlUrl,
    this.apkSize = 0,
  });
}

class UpdateService {
  static String appVersion = "1.0.5";
  static const String githubRepo = "T-m-m-s/FTT";
  static const String releasesApiUrl = "https://api.github.com/repos/$githubRepo/releases";

  static bool _hasCheckedStartup = false;
  static bool enableAutoCheck = true;
  static String? lastCheckError;

  /// Loads dynamic version from app package metadata
  static Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty && info.version != '0.0.0') {
        appVersion = info.version;
      }
    } catch (_) {}
    return appVersion;
  }

  /// Checks if [latest] is strictly newer than [current] semantically.
  static bool isVersionNewer(String latest, String current) {
    List<int> parseVersion(String v) {
      var clean = v.split('+').first.split('-').first;
      clean = clean.replaceAll(RegExp(r'[^0-9.]'), '');
      return clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    }

    final l = parseVersion(latest);
    final c = parseVersion(current);

    while (l.length < 3) {
      l.add(0);
    }
    while (c.length < 3) {
      c.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  /// Fetches latest release info from GitHub API. Returns null if up to date or on network error.
  static Future<AppReleaseInfo?> fetchLatestRelease() async {
    lastCheckError = null;
    try {
      final res = await http.get(
        Uri.parse(releasesApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'FreeTimeTracker-App',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 404) {
        lastCheckError = "Releases not found (HTTP 404). Ensure repository is public.";
        return null;
      }
      if (res.statusCode != 200) {
        lastCheckError = "GitHub returned HTTP ${res.statusCode}";
        return null;
      }

      final decoded = jsonDecode(res.body);
      Map<String, dynamic>? data;
      String highestVer = '0.0.0';

      if (decoded is List) {
        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            final tName = (item['tag_name'] ?? '').toString();
            final ver = tName.replaceFirst(RegExp(r'^[vV]'), '');
            if (isVersionNewer(ver, highestVer)) {
              highestVer = ver;
              data = item;
            }
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        data = decoded;
      }

      if (data == null) return null;

      final tagName = (data['tag_name'] ?? '').toString();
      final version = tagName.replaceFirst(RegExp(r'^[vV]'), '');
      final title = (data['name'] ?? tagName).toString();
      final body = (data['body'] ?? '').toString();
      final htmlUrl = (data['html_url'] ?? "https://github.com/$githubRepo/releases/latest").toString();

      String apkUrl = '';
      int apkSize = 0;

      final assets = data['assets'] as List<dynamic>? ?? [];
      for (var asset in assets) {
        final name = (asset['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = (asset['browser_download_url'] ?? '').toString();
          apkSize = (asset['size'] as int?) ?? 0;
          break;
        }
      }

      if (apkUrl.isEmpty) {
        apkUrl = "https://github.com/$githubRepo/releases/download/$tagName/app-release.apk";
      }

      return AppReleaseInfo(
        version: version,
        tagName: tagName,
        title: title,
        releaseNotes: body,
        apkDownloadUrl: apkUrl,
        htmlUrl: htmlUrl,
        apkSize: apkSize,
      );
    } catch (e) {
      debugPrint("UpdateService error checking release: $e");
      return null;
    }
  }

  /// Automatic check invoked on Home screen load.
  static Future<void> checkUpdateOnStartup(BuildContext context) async {
    if (!enableAutoCheck || _hasCheckedStartup) return;
    _hasCheckedStartup = true;

    // Small delay so home screen UI is rendered smoothly
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;

    await getAppVersion();
    final release = await fetchLatestRelease();
    if (release != null && isVersionNewer(release.version, appVersion)) {
      if (context.mounted) {
        showUpdateDialog(context, release);
      }
    }
  }

  /// Manual check triggered from settings or profile.
  static Future<void> checkUpdateManually(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          color: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  "Checking for updates on GitHub...",
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await getAppVersion();
    final release = await fetchLatestRelease();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

    if (release != null && isVersionNewer(release.version, appVersion)) {
      showUpdateDialog(context, release);
    } else if (lastCheckError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(lastCheckError!)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text("FreeTimeTracker is already up to date! (v$appVersion)"),
            ],
          ),
          backgroundColor: AppColors.statusCompleted,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Shows the update prompt dialog.
  static void showUpdateDialog(BuildContext context, AppReleaseInfo release) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _UpdateDialog(release: release),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final AppReleaseInfo release;

  const _UpdateDialog({required this.release});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = "";
  String? _errorMessage;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = "Connecting...";
      _errorMessage = null;
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.release.apkDownloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception("Server responded with HTTP ${response.statusCode}");
      }

      final contentLength = response.contentLength ?? widget.release.apkSize;
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/FreeTimeTracker-v${widget.release.version}.apk";
      final file = File(filePath);
      final sink = file.openWrite();

      int downloaded = 0;

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0 && mounted) {
            setState(() {
              _progress = (downloaded / contentLength).clamp(0.0, 1.0);
              final mbDownloaded = (downloaded / (1024 * 1024)).toStringAsFixed(1);
              final mbTotal = (contentLength / (1024 * 1024)).toStringAsFixed(1);
              _statusText = "Downloading: $mbDownloaded / $mbTotal MB (${(_progress * 100).toInt()}%)";
            });
          }
        },
        cancelOnError: true,
      ).asFuture();

      await sink.flush();
      await sink.close();

      if (!mounted) return;

      setState(() {
        _statusText = "Opening installer...";
      });

      final result = await OpenFile.open(filePath, type: "application/vnd.android.package-archive");
      if (result.type != ResultType.done && mounted) {
        setState(() {
          _errorMessage = "Could not open installer: ${result.message}";
          _isDownloading = false;
        });
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = "Download failed: $e";
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.release.htmlUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Update Available!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  "v${UpdateService.appVersion} → v${release.version}",
                  style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isDownloading) ...[
              const Text(
                "A new version of FreeTimeTracker is available with the latest improvements:",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    release.releaseNotes.isNotEmpty ? release.releaseNotes : "Bug fixes and performance improvements.",
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.accentOrange, fontSize: 12)),
              ],
            ] else ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  "Please keep the app open during download.",
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("LATER", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton.icon(
            icon: const Icon(Icons.open_in_browser_rounded, size: 16),
            label: const Text("GITHUB"),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
            onPressed: _openInBrowser,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text("UPDATE NOW"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: _startDownload,
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() => _isDownloading = false),
            child: const Text("CANCEL", style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ],
    );
  }
}
