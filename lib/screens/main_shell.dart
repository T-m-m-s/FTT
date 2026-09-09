import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../widgets/floating_nav_bar.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'timeline_screen.dart';
import 'statistics_screen.dart';
import 'search_screen.dart';
import 'media_detail_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTabIndex = 0;
  final List<int> _tabHistory = [0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkUpdateOnStartup(context);
    });
  }

  void _openDetail(LibraryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaDetailScreen(entry: entry),
      ),
    );
  }

  void _onTabSelected(int index) {
    if (_currentTabIndex == index) return;
    setState(() {
      _currentTabIndex = index;
      if (index == 0) {
        _tabHistory.clear();
        _tabHistory.add(0);
      } else {
        _tabHistory.remove(index);
        _tabHistory.add(index);
      }
    });
  }

  void _handleBackNavigation() {
    if (_currentTabIndex != 0) {
      setState(() {
        if (_tabHistory.length > 1) {
          _tabHistory.removeLast();
          _currentTabIndex = _tabHistory.last;
        } else {
          _currentTabIndex = 0;
          _tabHistory.clear();
          _tabHistory.add(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onOpenDetail: _openDetail),
      LibraryScreen(onOpenDetail: _openDetail),
      TimelineScreen(onOpenDetail: _openDetail),
      StatisticsScreen(onOpenDetail: _openDetail),
      SearchScreen(onOpenDetail: _openDetail),
    ];

    return PopScope(
      canPop: _currentTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Current Active Screen
            IndexedStack(
              index: _currentTabIndex,
              children: screens,
            ),

            // Floating Navigation Pill Dock (reproducing Nook's screenshot 1 & 2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: FloatingNavBar(
                  currentIndex: _currentTabIndex,
                  onTabSelected: _onTabSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
