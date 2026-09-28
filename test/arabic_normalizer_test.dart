import 'package:flutter_test/flutter_test.dart';
import 'package:quranapp/core/text/arabic_normalizer.dart';

void main() {
  const normalizer = ArabicNormalizerImpl();

  group('ArabicNormalizer Unit Tests', () {
    test('removeDiacritics strips all Arabic harakat and shaddah', () {
      expect(normalizer.removeDiacritics('يَفْعَلُونَ'), 'يفعلون');
      expect(normalizer.removeDiacritics('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ'), 'الحمد لله رب العالمين');
      expect(normalizer.removeDiacritics('إِيَّاكَ نَعْبُدُ'), 'إياك نعبد');
    });

    test('normalizeForSearch handles alef forms correctly', () {
      // توحيد همزة الوصل [ٱ]
      expect(normalizer.normalizeForSearch('ٱلْحَمْدُ'), 'الحمد');
      // توحيد همزة القطع المكسورة [إ]
      expect(normalizer.normalizeForSearch('إِنَّا'), 'انا');
      // توحيد همزة القطع المفتوحة [أ]
      expect(normalizer.normalizeForSearch('أَنْعَمْتَ'), 'انعمت');
      // توحيد المدة [آ]
      expect(normalizer.normalizeForSearch('آمَنُوا'), 'امنوا');
    });

    test('normalizeForSearch removes tatweel / kashida', () {
      expect(normalizer.normalizeForSearch('صِـــرَاطَ'), 'صراط');
      expect(normalizer.normalizeForSearch('الرَّحْمَٰــنِ'), 'الرحمن');
    });

    test('normalizeForSearch removes quranic stop signs and punctuation', () {
      expect(normalizer.normalizeForSearch('جَنَّاتٍ ۖ تَجْرِي'), 'جنات تجري');
      expect(normalizer.normalizeForSearch('لَا رَيْبَ ۛ فِيهِ ۛ هُدًى'), 'لا ريب فيه هدي');
    });

    test('normalizeForSearch unifies ta marbuta and alef maqsura', () {
      expect(normalizer.normalizeForSearch('الصَّلَاةَ'), 'الصلاه');
      expect(normalizer.normalizeForSearch('هُدًى'), 'هدي');
      expect(normalizer.normalizeForSearch('عَلَى'), 'علي');
    });

    test('tokenize splits input string into clean search tokens', () {
      final tokens = normalizer.tokenize('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
      expect(tokens, equals(['بسم', 'الله', 'الرحمن', 'الرحيم']));
    });

    test('containsCharactersInOrder checks ordered subsequence for fallback suggestion', () {
      // كلمة المتفاعلون تحتوي على حروف ف-ع-ل بالترتيب
      expect(
        normalizer.containsCharactersInOrder(word: 'المتفاعلون', root: 'فعل'),
        isTrue,
      );

      // كلمة يعلمون تحتوي على حروف ع-ل-م بالترتيب
      expect(
        normalizer.containsCharactersInOrder(word: 'يعلمون', root: 'علم'),
        isTrue,
      );

      // كلمة لف لا تحتوي على حروف ف-ع-ل بالترتيب الصحيح
      expect(
        normalizer.containsCharactersInOrder(word: 'لف', root: 'فعل'),
        isFalse,
      );

      // كلمة مقلوبة
      expect(
        normalizer.containsCharactersInOrder(word: 'لمع', root: 'علم'),
        isFalse,
      );
    });
  });
}
