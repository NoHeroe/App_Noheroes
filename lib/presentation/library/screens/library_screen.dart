import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';
import '../../../data/datasources/local/diary_service.dart';
import '../../../data/database/app_database.dart';
import 'diary_tab.dart';
import 'lore_tab.dart';
import 'works_tab.dart';
import 'collector_tab.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('BIBLIOTECA',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: const Color(0xFFC2A05A),
                              letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    indicatorColor: const Color(0xFFC2A05A),
                    labelColor: const Color(0xFFC2A05A),
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: GoogleFonts.cinzelDecorative(fontSize: 10,
                        letterSpacing: 1),
                    tabs: const [
                      Tab(text: 'DIÁRIO'),
                      Tab(text: 'LORE'),
                      Tab(text: 'OBRAS'),
                      Tab(text: 'COLEÇÃO'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  DiaryTab(),
                  LoreTab(),
                  WorksTab(),
                  CollectorTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
