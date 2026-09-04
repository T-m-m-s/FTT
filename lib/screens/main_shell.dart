import 'package:flutter/material.dart';
import '../models/library_entry.dart';
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

  void _openDetail(LibraryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaDetailScreen(entry: entry),
      ),
    );
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

    return Scaffold(
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
                onTabSelected: (index) {
                  setState(() => _currentTabIndex = index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
