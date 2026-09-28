import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';

/// شاشة البحث القرآني المباشر وبالجذر (SearchScreen).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchByRoot = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.push(
      '/search/results',
      extra: {'query': query, 'isRoot': _searchByRoot},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث في القرآن الكريم'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _searchByRoot
                    ? 'أدخل الجذر أو الكلمة (مثل: علم أو يعلمون)...'
                    : 'أدخل الكلمة أو العبارة (بتشكيل أو بدون)...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryEmerald),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitSearch(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('البحث بالجذر الصرفي للكلمة'),
              subtitle: const Text('استخراج الكلمات المرتبطة بالجذر وعرض مواضعها'),
              value: _searchByRoot,
              activeTrackColor: AppTheme.primaryEmerald,
              onChanged: (val) {
                setState(() {
                  _searchByRoot = val;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitSearch,
                icon: const Icon(Icons.search),
                label: const Text('تنفيذ البحث'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
