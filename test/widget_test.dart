import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quranapp/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('QuranStudyApp smoke test and navigation bar renders', (WidgetTester tester) async {
    // بناء التطبيق داخل ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: QuranStudyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من ظهور عنوان التطبيق في الشريط العلوي
    expect(find.text('مصحف الدراسة والبحث'), findsOneWidget);

    // التحقق من ظهور أقسام شريط التنقل السفلي
    expect(find.text('المصحف الشريف'), findsOneWidget);
    expect(find.text('البحث والدراسة'), findsOneWidget);
  });
}
