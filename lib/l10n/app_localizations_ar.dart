// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'فودراش';

  @override
  String get tagline => 'قرّروا. تسابقوا. اطلبوا. قسّموا.';

  @override
  String get currency => 'ج.م';

  @override
  String get cancel => 'إلغاء';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'لنبدأ';

  @override
  String get add => 'إضافة';

  @override
  String get start => 'ابدأ';

  @override
  String get lock => 'إغلاق';

  @override
  String get somethingWentWrong => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get onboardingTitle1 => 'اجمع أصحابك';

  @override
  String get onboardingBody1 =>
      'أنشئ غرفة وشارك رابطًا واحدًا. أصدقاؤك ينضمون في ثوانٍ بدون حساب.';

  @override
  String get onboardingTitle2 => 'صوّتوا أو تسابقوا';

  @override
  String get onboardingBody2 =>
      'اقترحوا المطاعم وصوّتوا. تعادلت الأصوات؟ المطاعم المتعادلة تتسابق.';

  @override
  String get onboardingTitle3 => 'قسّموا الفاتورة بعدل';

  @override
  String get onboardingBody3 =>
      'ارفع الإيصال، راجع الفاتورة، وكل شخص يرى المبلغ المطلوب منه بالضبط.';

  @override
  String get welcomeSubtitle => 'أصحاب. أكل. تحدي. مرح.';

  @override
  String get createRoom => 'إنشاء غرفة';

  @override
  String get joinRoom => 'انضم لغرفة';

  @override
  String get loginOrSignIn => 'تسجيل الدخول';

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get login => 'دخول';

  @override
  String get signUp => 'حساب جديد';

  @override
  String get welcomeBack => 'أهلًا بعودتك';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get loginSubtitle => 'سجّل الدخول للاحتفاظ بغرفك وسجلك.';

  @override
  String get signupSubtitle => 'احفظ غرفك وطلباتك وإجمالياتك.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get displayName => 'الاسم الظاهر';

  @override
  String get needAccount => 'ليس لديك حساب؟ أنشئ واحدًا';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get guestTitle => 'بأي اسم يناديك أصحابك؟';

  @override
  String get guestSubtitle => 'وضع الضيف، بدون حساب.';

  @override
  String get guest => 'ضيف';

  @override
  String get host => 'المضيف';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'حذف الحساب؟';

  @override
  String get deleteAccountBody =>
      'هذا الإجراء نهائي وسيحذف بيانات ملفك الشخصي.';

  @override
  String get deleteAccountConfirm => 'حذف';

  @override
  String get accountDeleted => 'تم حذف الحساب بنجاح.';

  @override
  String helloUser(String name) {
    return 'أهلًا، $name';
  }

  @override
  String get homePrompt => 'ناكل إيه مع بعض؟';

  @override
  String get createRoomSubtitle => 'ادعُ أصحابك وابدأ';

  @override
  String get joinRoomSubtitle => 'أدخل كود الغرفة';

  @override
  String get historyTitle => 'السجل';

  @override
  String get historySubtitle => 'الغرف والفواتير السابقة';

  @override
  String get historyDetailTitle => 'طلب سابق';

  @override
  String get historyNoReceipt => 'لا توجد صورة إيصال';

  @override
  String get nameYourHangout => 'سمِّ الجلسة';

  @override
  String get roomNameHint => 'غداء الجمعة (اختياري)';

  @override
  String get howDecide => 'كيف نقرر؟';

  @override
  String get allowGuests => 'السماح للضيوف';

  @override
  String get modeRaceDirect => 'إضافة مطاعم ← سباق';

  @override
  String get modeRaceDirectHint => 'اقترحوا المطاعم ثم سباق بينهم. سريع وممتع.';

  @override
  String get modeVoteWithTieRace => 'إضافة مطاعم ← تصويت (سباق عند التعادل)';

  @override
  String get modeVoteWithTieRaceHint =>
      'الجميع يصوّت. لو تعادل، المطاعم المتعادلة تتسابق.';

  @override
  String get modeVoteOnly => 'إضافة مطاعم ← تصويت فقط';

  @override
  String get modeVoteOnlyHint =>
      'الجميع يصوّت. بدون سباق — المضيف يختار عند التعادل.';

  @override
  String get pickTiedWinner => 'تعادل الأصوات — اختر الفائز';

  @override
  String get pickTiedWinnerHint => 'اختر واحدًا من المطاعم المتعادلة.';

  @override
  String get hostPickWinner => 'اختيار كفائز';

  @override
  String get enterRoomCode => 'أدخل كود الغرفة';

  @override
  String get roomCodeHint => '6 خانات · حروف وأرقام كبيرة';

  @override
  String get roomCodeLabel => 'كود الغرفة';

  @override
  String get tapCodeToCopy => 'اضغط على الكود للنسخ';

  @override
  String get codeCopied => 'تم نسخ الكود';

  @override
  String roomCode(String code) {
    return 'كود $code';
  }

  @override
  String get inviteFriends => 'ادعُ أصحابك';

  @override
  String get leaveRoom => 'مغادرة الغرفة';

  @override
  String get leaveRoomTitle => 'مغادرة الغرفة؟';

  @override
  String get leaveRoomBody =>
      'هتغادر الغرفة. تقدر تدخل تاني بالكود لو لسه مفتوحة.';

  @override
  String get cancelRoom => 'إلغاء الغرفة';

  @override
  String get cancelRoomTitle => 'إلغاء الغرفة؟';

  @override
  String get cancelRoomBody =>
      'هتنتهي الغرفة للجميع. أصحابك مش هيقدروا يدخلوا بعد كده.';

  @override
  String playersReady(int count) {
    return '$count لاعبين جاهزون';
  }

  @override
  String get waitingForFriends => 'في انتظار الأصدقاء…';

  @override
  String get waitingForHostStart => 'في انتظار بدء المضيف';

  @override
  String get hostWillStart => 'استنى شوية، المضيف هيبدأ قريب.';

  @override
  String get startGameQuestion => 'نبدأ اللعبة؟';

  @override
  String startAnyway(int count) {
    return 'يوجد $count لاعب فقط. نبدأ على أي حال؟';
  }

  @override
  String inviteMessage(String room, String code) {
    return 'انضم إلى $room على فودراش! الكود: $code';
  }

  @override
  String get suggestRestaurants => 'اقترح مطاعم';

  @override
  String get cravingPrompt => 'نفسنا في إيه؟';

  @override
  String get raceHint => 'كل مطعم يتحول إلى متسابق.';

  @override
  String get voteHint => 'الجميع يصوّت بعد انتهاء الاقتراحات.';

  @override
  String get addRestaurant => 'إضافة مطعم';

  @override
  String get restaurantName => 'اسم المطعم';

  @override
  String get chooseCategory => 'اختر التصنيف';

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String get emptySuggestions => 'لا توجد مطاعم مقترحة بعد.';

  @override
  String get emptySuggestionsHint => 'اضغط إضافة مطعم للبدء.';

  @override
  String get needTwoRestaurants => 'نحتاج مطعمين على الأقل';

  @override
  String get startVoting => 'ابدأ التصويت';

  @override
  String get startRace => 'ابدأ السباق';

  @override
  String bySomeone(String name) {
    return 'بواسطة $name';
  }

  @override
  String get catBurger => 'برجر';

  @override
  String get catPizza => 'بيتزا';

  @override
  String get catChicken => 'دجاج';

  @override
  String get catShawarma => 'شاورما';

  @override
  String get catGrill => 'مشويات';

  @override
  String get catSeafood => 'أسماك';

  @override
  String get catAsian => 'آسيوي';

  @override
  String get catPasta => 'مكرونة';

  @override
  String get catSushi => 'سوشي';

  @override
  String get catMexican => 'مكسيكي';

  @override
  String get catKoshary => 'كشري';

  @override
  String get catSandwich => 'ساندويتش';

  @override
  String get catBreakfast => 'فطار';

  @override
  String get catSalad => 'صحي';

  @override
  String get catDessert => 'حلويات';

  @override
  String get catDrinks => 'مشروبات';

  @override
  String get catOther => 'أخرى';

  @override
  String get chooseFavorite => 'اختر المفضل لديك';

  @override
  String get oneVote => 'لديك صوت واحد.';

  @override
  String get tieHint => 'تعادلت الأصوات؟ المطاعم المتعادلة تتسابق.';

  @override
  String get vote => 'صوّت';

  @override
  String get switchVote => 'تغيير';

  @override
  String get yourVote => 'صوتك';

  @override
  String get votedFor => 'صوّتّ لـ';

  @override
  String get changeMind => 'غيرت رأيك؟';

  @override
  String get revealWinner => 'أظهر الفائز';

  @override
  String get waitingReveal => 'في انتظار إعلان المضيف…';

  @override
  String get results => 'النتائج';

  @override
  String get winner => 'الفائز';

  @override
  String votesCount(int count) {
    return '$count صوت';
  }

  @override
  String votedProgress(int voted, int total) {
    return 'صوّت $voted من $total';
  }

  @override
  String get tieBanner => 'تعادل! المطاعم المتعادلة تحسمها بسباق.';

  @override
  String tieSnack(int count) {
    return 'تعادل! $count مطاعم تتسابق.';
  }

  @override
  String get drawTitle => 'تعادل!';

  @override
  String drawSubtitle(int count) {
    return '$count مطاعم متعادلة. السباق يحسم الفائز.';
  }

  @override
  String get tiedRestaurants => 'المطاعم المتعادلة';

  @override
  String get goToRace => 'اذهب للسباق';

  @override
  String get waitingHostStartRace => 'بانتظار المضيف لبدء السباق…';

  @override
  String get noRestaurantsToVote => 'لا توجد مطاعم للتصويت.';

  @override
  String get raceLabel => 'سباق المطاعم';

  @override
  String get tiebreakerLabel => 'سباق كسر التعادل';

  @override
  String get tiebreakerPrompt => 'الأصوات متعادلة، خلي السباق يقرر!';

  @override
  String get racePrompt => 'نشوف مين هيكسب!';

  @override
  String get raceFastestPrompt => 'نشوف مين الأسرع!';

  @override
  String get raceStartsIn => 'السباق يبدأ خلال';

  @override
  String get howItWorksRace => 'هنسابق كل المطاعم والفائز هو اللي هنطلب منه!';

  @override
  String get letsGo => 'يلا ننطلق!';

  @override
  String get getReady => 'استعدوا!';

  @override
  String get neckAndNeck => 'المنافسة قوية…';

  @override
  String get go => 'انطلق!';

  @override
  String get weHaveWinner => 'لدينا فائز!';

  @override
  String get wonTheRace => 'فاز بالسباق';

  @override
  String get wonTiebreaker => 'فاز بسباق كسر التعادل';

  @override
  String get letsOrder => 'يلا نطلب';

  @override
  String get waitingHostContinue => 'في انتظار المضيف للمتابعة…';

  @override
  String get liningUp => 'في انتظار اصطفاف المتسابقين…';

  @override
  String get orderingTonightFrom => 'النهاردة هنطلب من';

  @override
  String viaMode(String mode) {
    return 'عن طريق $mode';
  }

  @override
  String get startOrdering => 'ابدأ الطلب';

  @override
  String get waitingHostOrdering => 'في انتظار بدء المضيف للطلب…';

  @override
  String get yourOrder => 'طلبك';

  @override
  String orderingFrom(String name) {
    return 'الطلب من $name';
  }

  @override
  String get whatDoYouWant => 'عايز تطلب إيه؟';

  @override
  String get addItem => 'إضافة صنف';

  @override
  String get itemName => 'اسم الصنف';

  @override
  String get quantity => 'الكمية';

  @override
  String get priceEgp => 'السعر (ج.م)';

  @override
  String get notes => 'ملاحظات';

  @override
  String get subtotal => 'الإجمالي الفرعي';

  @override
  String get submitMyOrder => 'إرسال طلبي';

  @override
  String get emptyOrderTitle => 'لم تضف طلبًا';

  @override
  String get emptyOrderBody =>
      'قائمة الأصناف فارغة. هل تريد إرسال طلب فارغ؟ سيظهر للمجموعة أنك لا تطلب طعامًا.';

  @override
  String get sendEmptyOrder => 'إرسال طلب فارغ';

  @override
  String get orderSubmitted => 'تم إرسال طلبك.';

  @override
  String get yourSubmittedOrder => 'طلبك المُرسل';

  @override
  String get copyOrder => 'نسخ الطلب';

  @override
  String get orderCopied => 'تم نسخ الطلب';

  @override
  String get saveOrderForNext => 'حفظ للمرات القادمة';

  @override
  String get orderSavedForNext => 'تم حفظ الطلب للمرات القادمة.';

  @override
  String get savedOrderLoaded => 'تم تحميل الطلب المحفوظ.';

  @override
  String get noItemsToSave => 'لا توجد عناصر للحفظ.';

  @override
  String get savedOrders => 'طلبات محفوظة';

  @override
  String get useSavedOrder => 'استخدم';

  @override
  String get deleteSavedOrder => 'حذف';

  @override
  String get editOrder => 'تعديل الطلب';

  @override
  String get viewGroupOrders => 'عرض طلبات المجموعة';

  @override
  String get noItemsYet => 'لا توجد أصناف بعد. أضف شيئًا لذيذًا.';

  @override
  String get groupOrders => 'طلبات المجموعة';

  @override
  String ordersSubmitted(int done, int total) {
    return 'تم إرسال $done من $total طلبات.';
  }

  @override
  String get lockOrders => 'إغلاق الطلبات';

  @override
  String get lockOrdersQuestion => 'إغلاق الطلبات؟';

  @override
  String get lockOrdersBody =>
      'بعد الإغلاق لا يمكن للمشاركين التعديل. ستظهر الطلبات المجمّعة لإرسالها للمطعم.';

  @override
  String get submitted => 'تم الإرسال';

  @override
  String get notSubmitted => 'لم يُرسل';

  @override
  String get orderDetailsTitle => 'طلب المطعم';

  @override
  String get orderDetailsPrompt =>
      'أرسل هذا الطلب للمطعم (واتساب، اتصال، أو تطبيق توصيل).';

  @override
  String get combinedOrder => 'الطلب المجمّع';

  @override
  String get combinedOrderHint =>
      'نفس الأصناف من أشخاص مختلفين تُدمَج في سطر واحد.';

  @override
  String sharedBy(String people) {
    return 'مشترك: $people';
  }

  @override
  String orderedBy(String people) {
    return 'طلبه: $people';
  }

  @override
  String get perPersonOrders => 'حسب الشخص';

  @override
  String get shareWithRestaurant => 'مشاركة';

  @override
  String get orderDetailsCopied => 'تم نسخ الطلب — الصقه للمطعم.';

  @override
  String get continueToReceipt => 'المتابعة للإيصال';

  @override
  String get waitingHostReceipt => 'في انتظار متابعة المضيف…';

  @override
  String get uploadReceiptTitle => 'رفع الإيصال';

  @override
  String get uploadReceiptPrompt => 'ارفع الإيصال';

  @override
  String get receiptFrameHint => 'التقط صورة أو اختر من المعرض';

  @override
  String get receiptTotalHint => 'إجمالي الإيصال (ج.م)';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get retake => 'إعادة التصوير';

  @override
  String get upload => 'رفع';

  @override
  String get receiptUploaded => 'تم رفع الإيصال.';

  @override
  String get skipReceipt => 'تخطي الإيصال';

  @override
  String get skipReceiptHint => 'كل واحد يدفع طلبه.';

  @override
  String get payOwnOrderBanner => 'بدون إيصال — كل واحد يدفع طلبه.';

  @override
  String get costSharing => 'تقسيم التكلفة';

  @override
  String get reviewFinalBill => 'راجع الفاتورة النهائية';

  @override
  String get expectedOrders => 'إجمالي الطلبات المتوقع';

  @override
  String get receiptTotal => 'إجمالي الإيصال';

  @override
  String get difference => 'الفرق';

  @override
  String get additionalCosts => 'تكاليف إضافية';

  @override
  String get delivery => 'التوصيل';

  @override
  String get service => 'الخدمة';

  @override
  String get tax => 'الضريبة';

  @override
  String get discount => 'الخصم';

  @override
  String get recalculate => 'إعادة الحساب';

  @override
  String get participants => 'المشاركون';

  @override
  String get sharesTotal => 'إجمالي الحصص';

  @override
  String get confirmAndSend => 'تأكيد وإرسال';

  @override
  String orderPlusExtras(String order, String extras) {
    return 'الطلب $order + إضافات $extras';
  }

  @override
  String get paymentSummary => 'ملخص الدفع';

  @override
  String get yourTotal => 'إجماليك';

  @override
  String get breakdown => 'التفاصيل';

  @override
  String get orderLabel => 'الطلب';

  @override
  String get extrasFees => 'إضافات / رسوم';

  @override
  String get adjustment => 'تعديل';

  @override
  String get total => 'الإجمالي';

  @override
  String get markAsPaid => 'تحديد كمدفوع';

  @override
  String get requestPaid => 'دفعت — أبلغ المضيف';

  @override
  String get paymentRequested => 'بانتظار تأكيد المضيف';

  @override
  String get paymentRequestedStatus => 'طلب تأكيد الدفع';

  @override
  String get confirmPaid => 'تأكيد الدفع';

  @override
  String get markUnpaid => 'غير مدفوع';

  @override
  String get statusPaid => 'الحالة: مدفوع';

  @override
  String get paid => 'مدفوع';

  @override
  String get unpaid => 'غير مدفوع';

  @override
  String everyonePaid(int paid, int total) {
    return 'الجميع ($paid/$total دفعوا)';
  }

  @override
  String get roomCompleteTitle => 'تم التسوية!';

  @override
  String get roomCompleteBody => 'الجميع دفعوا. الغرفة مكتملة.';

  @override
  String participantsCount(int count) {
    return '$count مشاركين';
  }

  @override
  String paidCount(int paid, int total) {
    return 'مدفوع: $paid/$total';
  }

  @override
  String remainingCount(int remaining, int total) {
    return 'متبقي: $remaining/$total';
  }

  @override
  String get backToHome => 'العودة للرئيسية';

  @override
  String get noCompletedRooms => 'لا توجد غرف مكتملة بعد.';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get notSignedIn => 'لم تسجل الدخول';

  @override
  String get errAuthFailed => 'فشل التحقق من الهوية.';

  @override
  String get errPermissionDenied => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';

  @override
  String get errNotFound => 'غير موجود.';

  @override
  String get errOffline => 'أنت غير متصل. ستتم المزامنة عند عودة الاتصال.';

  @override
  String get errNotSignedIn => 'لم تسجل الدخول.';

  @override
  String get errSignInToCreateRoom => 'سجّل الدخول لإنشاء غرفة.';

  @override
  String get errSignInToJoinRoom => 'سجّل الدخول للانضمام إلى غرفة.';

  @override
  String get errInvalidRoomCode => 'رمز الغرفة غير صالح.';

  @override
  String get errRoomNotFound => 'الغرفة غير موجودة.';

  @override
  String get errRestaurantNotFound => 'المطعم غير موجود.';

  @override
  String get errRemoveRestaurant => 'تعذر حذف هذا المطعم.';

  @override
  String get errRoomEnded => 'هذه الغرفة انتهت بالفعل.';

  @override
  String get errGuestsNotAllowed => 'الضيوف غير مسموح لهم في هذه الغرفة.';

  @override
  String get errRoomFull => 'الغرفة ممتلئة.';

  @override
  String get errJoinRoomFirst => 'انضم إلى الغرفة أولاً.';

  @override
  String get errEmailPasswordRequired =>
      'البريد الإلكتروني وكلمة المرور مطلوبان.';

  @override
  String get errAllFieldsRequired => 'جميع الحقول مطلوبة.';

  @override
  String get errLoginFailed => 'فشل تسجيل الدخول.';

  @override
  String get errRegistrationFailed => 'فشل إنشاء الحساب.';

  @override
  String get errGuestSignInFailed => 'فشل الدخول كضيف.';

  @override
  String get signupSuccessLogin =>
      'تم إنشاء الحساب. فعّل بريدك إن لزم، ثم سجّل الدخول.';

  @override
  String get errActivateAccountFirst => 'فعّل حسابك أولاً قبل الانضمام.';

  @override
  String get guestJoinInviteTitle => 'انضم للغرفة كضيف';

  @override
  String get guestJoinInviteSubtitle =>
      'أدخل اسم العرض للانضمام عبر الدعوة — بدون حساب.';

  @override
  String get errNeedTwoRestaurants => 'نحتاج مطعمين على الأقل.';

  @override
  String get errRestaurantNameRequired => 'اسم المطعم مطلوب.';

  @override
  String get errSuggestionLimit => 'تم الوصول لحد الاقتراحات.';

  @override
  String get errVotingNotOpen => 'التصويت غير مفتوح.';

  @override
  String get errNoVotesYet => 'لا توجد أصوات بعد.';

  @override
  String get errHostPickVoteOnly => 'اختيار المضيف متاح فقط لغرف التصويت فقط.';

  @override
  String get errPickTiedRestaurant => 'اختر أحد المطاعم المتعادلة.';

  @override
  String get errOrdersLocked => 'الطلبات مغلقة.';

  @override
  String get errEnterReceiptTotal => 'أدخل إجمالي الفاتورة.';

  @override
  String get errEnterValidReceiptTotal => 'أدخل إجمالي فاتورة صالح.';

  @override
  String get errSelectReceiptImage => 'اختر صورة الفاتورة أولاً.';

  @override
  String get errReceiptUploadFailed => 'تعذر رفع الإيصال. حاول مرة أخرى.';

  @override
  String get errRoomNotReady => 'الغرفة غير جاهزة.';

  @override
  String get errNoOrdersToSplit => 'لا توجد طلبات مُرسلة للتقسيم.';

  @override
  String get errCalculateSplitFirst => 'احسب التقسيم أولاً.';

  @override
  String errSharesMustEqual(String shares, String receipt) {
    return 'الحصص ($shares) يجب أن تساوي الفاتورة ($receipt).';
  }
}
