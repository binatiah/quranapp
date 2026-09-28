import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../quran_reader/presentation/controllers/quran_providers.dart';

/// الشاشة الرئيسية للتطبيق (HomeScreen) تجمع بين أقسام المصحف والبحث والدراسة مع ربط موضع القراءة الحي.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مصحف الدراسة والبحث'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'المفضلة',
            onPressed: () => context.push('/bookmarks'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildQuranSection(context),
          _buildStudySection(context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'المصحف الشريف',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search),
            label: 'البحث والدراسة',
          ),
        ],
      ),
    );
  }

  /// بناء قسم المصحف التقليدي مع جلب آخر موضع قراءة ديناميكيًا من SQLite
  Widget _buildQuranSection(BuildContext context) {
    final readingPositionState = ref.watch(readingPositionNotifierProvider);
    final surahListState = ref.watch(surahListNotifierProvider);
    final surahs = surahListState.uiState.data ?? [];

    int surahId = 1;
    int ayahNum = 1;
    String surahName = 'الفاتحة';

    if (readingPositionState.isSuccess && readingPositionState.data != null) {
      final pos = readingPositionState.data!;
      surahId = pos.surahId;
      ayahNum = pos.ayahNumber;
      final matchedSurah = surahs.where((s) => s.id == surahId);
      if (matchedSurah.isNotEmpty) {
        surahName = matchedSurah.first.nameArabic;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقة آخر موضع قراءة ديناميكية
        Card(
          color: Theme.of(context).brightness == Brightness.light
              ? AppTheme.primaryEmerald
              : AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_added, color: AppTheme.goldAccent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'آخر موضع قراءة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'سورة $surahName - الآية $ayahNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/reader/$surahId?ayah=$ayahNum');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryGold,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('متابعة التلاوة'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // بطاقة استعراض قائمة السور الـ 114
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              child: Icon(Icons.format_list_bulleted),
            ),
            title: const Text(
              'فهرس السور',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text('استعراض سور القرآن الكريم الـ 114 سورة كاملة'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/surahs'),
          ),
        ),
        const SizedBox(height: 12),

        // بطاقة المفضلة
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: Colors.white,
              child: Icon(Icons.star_border),
            ),
            title: const Text(
              'الآيات المحفوظة والمفضلة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text('الرجوع إلى الآيات التي قمت بحفظها وملاحظاتك الشخصية'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/bookmarks'),
          ),
        ),
      ],
    );
  }

  /// بناء قسم البحث والدراسة القرآنية
  Widget _buildStudySection(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقة البحث في القرآن الكريم
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.primaryEmerald, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'البحث والتحليل القرآني',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ابحث بالكلمة المجردة، بدون تشكيل، أو بالجذر الصرفي للوصول إلى دلالات الكلمات ومواضع ورودها.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('فتح شاشة البحث'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // دراسة الجذور اللغوية
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              child: Icon(Icons.account_tree_outlined),
            ),
            title: const Text(
              'شاشة دراسة الجذر',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text('تحليل الكلمات القرآنية المشتقة وإحصاءاتها ومواضعها'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/roots/علم'),
          ),
        ),
      ],
    );
  }
}
