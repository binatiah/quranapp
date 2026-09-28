import 'package:equatable/equatable.dart';

/// تعداد حالات واجهة المستخدم الأساسية
enum UIStatus {
  /// الحالة الأولية قبل بدء أي عملية
  initial,

  /// حالة جاري التحميل وجلب البيانات
  loading,

  /// حالة النجاح وتوفر البيانات
  success,

  /// حالة اكتمال العملية بنجاح مع عدم وجود بيانات مطابقة
  empty,

  /// حالة حدوث خطأ أثناء المعالجة
  error,
}

/// غلاف حالة واجهة المستخدم القابلة لإعادة الاستخدام في النماذج المعمارية (ViewModel/Notifier)
class UIState<T> extends Equatable {
  /// الحالة الراهنة للعملية
  final UIStatus status;

  /// البيانات المحملة في حالة النجاح
  final T? data;

  /// رسالة الخطأ باللغة العربية في حالة الفشل
  final String? errorMessage;

  /// المنشئ الثابت لتهيئة كائن الحالة
  const UIState({
    required this.status,
    this.data,
    this.errorMessage,
  });

  /// إنشاء حالة أولية (Initial)
  factory UIState.initial() => const UIState(status: UIStatus.initial);

  /// إنشاء حالة جاري التحميل (Loading)
  factory UIState.loading() => const UIState(status: UIStatus.loading);

  /// إنشاء حالة نجاح مع توفير البيانات (Success)
  factory UIState.success(T data) => UIState(status: UIStatus.success, data: data);

  /// إنشاء حالة فراغ النتيجة (Empty)
  factory UIState.empty() => const UIState(status: UIStatus.empty);

  /// إنشاء حالة خطأ مع رسالة توضيحية (Error)
  factory UIState.error(String message) => UIState(status: UIStatus.error, errorMessage: message);

  /// التحقق السريع من كون الحالة جاري التحميل
  bool get isLoading => status == UIStatus.loading;

  /// التحقق السريع من نجاح العملية
  bool get isSuccess => status == UIStatus.success;

  /// التحقق السريع من كون النتيجة فارغة
  bool get isEmpty => status == UIStatus.empty;

  /// التحقق السريع من وجود خطأ
  bool get isError => status == UIStatus.error;

  /// التحقق من كون الحالة أولية
  bool get isInitial => status == UIStatus.initial;

  @override
  List<Object?> get props => [status, data, errorMessage];
}
