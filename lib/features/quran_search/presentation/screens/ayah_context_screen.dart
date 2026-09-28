import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// شاشة سياق الآيات القرآنية (AyahContextScreen) لعرض الآيات السابقة واللاحقة مع دمج النطاقات المتداخلة.
class AyahContextScreen extends StatefulWidget {
  final int initialBeforeCount;
  final int initialAfterCount;

  const AyahContextScreen({
    super.key,
    this.initialBeforeCount = 2,
    this.initialAfterCount = 2,
  });

  @override
  State<AyahContextScreen> createState() => _AyahContextScreenState();
}

class _AyahContextScreenState extends State<AyahContextScreen> {
  late int _beforeCount;
  late int _afterCount;
  bool _allowCrossSurah = false;

  @override
  void initState() {
    super.initState();
    _beforeCount = widget.initialBeforeCount;
    _afterCount = widget.initialAfterCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياق الآيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'تعديل نطاق السياق',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // شريط معلومات السياق
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السابق: $_beforeCount آيات | اللاحق: $_afterCount آيات',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showSettingsDialog,
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('تغيير'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // تمثيل سياق الآيات المدمجة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'سورة البقرة [النطاق: 18 إلى 22]',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(height: 24),

                  // آية سابقة
                  _buildAyahLine(
                    number: 19,
                    text: 'أَوْ كَصَيِّبٍ مِّنَ السَّمَاءِ فِيهِ ظُلُمَاتٌ وَرَعْدٌ وَبَرْقٌ...',
                    isTarget: false,
                  ),
                  const SizedBox(height: 12),

                  // الآية المطابقة للبحث (مميزة بصرياً)
                  _buildAyahLine(
                    number: 20,
                    text: 'يَكَادُ الْبَرْقُ يَخْطَفُ أَبْصَارَهُمْ ۖ كُلَّمَا أَضَاءَ لَهُم مَّشَوْا فِيهِ...',
                    isTarget: true,
                  ),
                  const SizedBox(height: 12),

                  // آية لاحقة
                  _buildAyahLine(
                    number: 21,
                    text: 'يَا أَيُّهَا النَّاسُ اعْبُدُوا رَبَّكُمُ الَّذِي خَلَقَكُمْ وَالَّذِينَ مِن قَبْلِكُمْ لَعَلَّكُمْ تَتَّقُونَ',
                    isTarget: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء سطر الآية مع تمييز الآية الهدف
  Widget _buildAyahLine({
    required int number,
    required String text,
    required bool isTarget,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTarget ? AppTheme.secondaryGold.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isTarget
            ? Border.all(color: AppTheme.secondaryGold.withValues(alpha: 0.5), width: 1.2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الآية ($number)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isTarget ? AppTheme.secondaryGold : AppTheme.primaryEmerald,
                ),
              ),
              if (isTarget)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'الآية المطابقة',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.8,
              fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// عرض مربع حوار لتعديل نطاق السياق
  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('خيارات سياق الآيات'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الآيات السابقة:'),
                  DropdownButton<int>(
                    value: _beforeCount,
                    items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _beforeCount = val);
                        setState(() => _beforeCount = val);
                      }
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الآيات اللاحقة:'),
                  DropdownButton<int>(
                    value: _afterCount,
                    items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text('$i'))),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _afterCount = val);
                        setState(() => _afterCount = val);
                      }
                    },
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('امتداد السياق بين السور'),
                value: _allowCrossSurah,
                activeTrackColor: AppTheme.primaryEmerald,
                onChanged: (val) {
                  setDialogState(() => _allowCrossSurah = val);
                  setState(() => _allowCrossSurah = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تم'),
            ),
          ],
        ),
      ),
    );
  }
}
