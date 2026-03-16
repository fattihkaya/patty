import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

/// Centralized localization strings for the entire app.
/// Usage: S.of(context).login
class S {
  final String languageCode;

  S._(this.languageCode);

  static S of(BuildContext context) {
    final locale = context.read<LocaleProvider>().locale;
    return S._(locale.languageCode);
  }

  static S ofLang(String langCode) => S._(langCode);

  // ─── Auth ───
  String get appName => 'Patty';
  String get appSlogan =>
      _t('Your pet\'s digital diary', 'Dostunuzun dijital günlüğü');
  String get login => _t('Log In', 'Giriş Yap');
  String get register => _t('Sign Up', 'Kayıt Ol');
  String get email => _t('Email', 'E-posta');
  String get password => _t('Password', 'Şifre');
  String get confirmPassword => _t('Confirm Password', 'Şifreyi Onayla');
  String get noAccount => _t('Don\'t have an account? ', 'Hesabın yok mu? ');
  String get haveAccount =>
      _t('Already have an account? ', 'Zaten hesabın var mı? ');
  String get joinUs => _t('Join Us!', 'Aramıza Katıl!');
  String get joinSubtitle => _t(
      'We\'re ready to create the best digital experience for your pet.',
      'Dostunuz için en iyi dijital deneyimi hazırlamaya hazırız.');
  String get signUpSuccess => _t('Registration successful! You can now log in.',
      'Kayıt başarılı! Giriş yapabilirsiniz.');
  String get passwordsNotMatch =>
      _t('Passwords do not match!', 'Şifreler uyuşmuyor!');
  String get validEmail =>
      _t('Enter a valid email', 'Geçerli bir e-posta girin');
  String get minPassword => _t('Password must be at least 6 characters',
      'Şifre en az 6 karakter olmalı');
  String get createAccount => _t('Create Account', 'Yeni Hesap Oluştur');
  String get logout => _t('Log Out', 'Çıkış Yap');

  // ─── Navigation ───
  String get timeline => _t('Timeline', 'Zaman Çizelgesi');
  String get myPets => _t('My Pets', 'Dostlarım');
  String get profile => _t('Profile', 'Profil');
  String get diary => _t('Diary', 'Günlük');
  String get health => _t('Health', 'Sağlık');

  // ─── Timeline / Discover ───
  String get discover => _t('Discover', 'Keşfet');
  String get noPublicPosts =>
      _t('No shared moments yet', 'Henüz paylaşılan bir anı yok');
  String get refreshed => _t('Refreshed', 'Yenilendi');

  // ─── Home Screen ───
  String get petAITimeline => _t('Patty Timeline', 'Patty Zaman Çizelgesi');
  String get totalMemories => _t('Total Memories', 'Toplam Anı');
  String get noRecordsYet => _t('No records yet', 'Henüz kayıt yok');
  String get addedToday => _t('Added a memory today', 'Bugün yeni anı ekledin');
  String daysAgo(int days) =>
      _t('Recorded $days days ago', '$days gün önce kayıt yaptın');
  String get aiMood => _t('Patty Mood', 'Patty Mood');
  String get noAIComment =>
      _t('No Patty comment yet.', 'Henüz bir Patty yorumu yok.');
  String get addPhotoForAI => _t(
      'Add a photo for Patty analysis.', 'Patty yorum için fotoğraf ekle.');
  String lastUpdate(String date) =>
      _t('Last update · $date', 'Son güncelleme · $date');
  String get streak => _t('Streak', 'Seri');
  String longestStreak(int days) => _t('Longest: $days', 'En uzun: $days');
  String get patiPoints => _t('Paw Points', 'Pati Puanı');
  String togetherDay(int day) =>
      _t('Day $day together!', 'Birlikte $day. gününüz!');
  String keepCollecting(String name) => _t(
      'Keep collecting memories with $name',
      '$name ile anılarını biriktirmeye devam et');
  String get noPetYet =>
      _t('You don\'t have a pet yet!', 'Henüz bir dostun yok!');
  String get createProfile => _t(
      'Create their profile now to start collecting memories.',
      'Onun anılarını biriktirmeye başlamak için hemen profilini oluştur.');
  String get addYourPet => _t('Add Your Pet', 'Dostunu Ekle');
  String get healthScore => _t('Health Score', 'Sağlık Skoru');
  String get excellent => _t('Excellent', 'Mükemmel');
  String get good => _t('Good', 'İyi');
  String get average => _t('Average', 'Orta');
  String get attention => _t('Attention', 'Dikkat');

  // ─── Health Screen ───
  String get statisticsDashboard =>
      _t('Statistics Dashboard', 'İstatistik Dashboard');
  String overviewFor(String name) =>
      _t('Overview for $name', '$name için genel görünüm');
  String get avgMood => _t('Avg Mood', 'Ort. Mood');
  String get energy => _t('Energy', 'Enerji');
  String get totalRecords => _t('Total Records', 'Toplam Kayıt');
  String get moodEnergyTrend =>
      _t('Mood & Energy Trend', 'Mood & Enerji Trendi');
  String get last7Days => _t('Last 7 Days', 'Son 7 Gün');
  String get healthVitals => _t('Health Vitals', 'Sağlık Vitals');
  String metrics(int count) => _t('$count metrics', '$count metrik');
  String get healthSummary => _t('Health Summary', 'Sağlık Özeti');
  String get noPetSelected =>
      _t('No pet selected yet.', 'Henüz bir dost seçilmedi.');
  String get noPetSelectedHint => _t(
      'Select a pet on the Home tab to see statistics here.',
      'Home sekmesinde bir dost seçtiğinde istatistikler burada görünecek.');
  String noStatsFor(String name) =>
      _t('No statistics for $name yet', '$name için henüz istatistik yok');
  String get noStatsHint => _t(
      'Mood and energy trends will appear here as Patty analyses are created.',
      'Patty yorumları oluştukça mood ve enerji trendleri burada takip edilecek.');
  String get refresh => _t('Refresh', 'Yenile');
  String lastRecord(String date) =>
      _t('Last record: $date', 'Son kayıt: $date');
  String get detail => _t('Detail', 'Detay');

  // ─── Profile Screen ───
  String get petProfile => _t('Pet Profile', 'Pet Profili');
  String get changePet => _t('Switch Pet', 'Pet Değiştir');
  String get addNewPet => _t('Add New Pet', 'Yeni Pet Ekle');
  String get editPetProfile => _t('Edit Pet Profile', 'Pet Profilini Düzenle');
  String get accountSettings => _t('Account Settings', 'Hesap Ayarları');
  String get birthDate => _t('Birth Date', 'Doğum Tarihi');
  String get weight => _t('Weight', 'Ağırlık');
  String get gender => _t('Gender', 'Cinsiyet');
  String get notSpecified => _t('Not specified', 'Belirtilmedi');
  String get familyMembers => _t('Family Members', 'Aile Üyeleri');
  String get noMembersYet => _t('No members added yet', 'Henüz üye eklenmemiş');
  String get addNewMember => _t('Add New Member', 'Yeni Üye Ekle');
  String get emailAddress => _t('Email Address', 'E-posta Adresi');
  String get role => _t('Role', 'Rol');
  String get owner => _t('Owner', 'Sahip');
  String get editor => _t('Editor', 'Editör');
  String get viewer => _t('Viewer', 'İzleyici');
  String get addMember => _t('Add Member', 'Üye Ekle');
  String get adding => _t('Adding...', 'Ekleniyor...');
  String get memberAdded => _t('Member added', 'Üye eklendi');
  String get memberRemoved => _t('Member removed', 'Üye kaldırıldı');
  String get noPetProfile =>
      _t('Don\'t have a pet yet?', 'Henüz bir dostun yok mu?');

  // ─── Settings Screen ───
  String get myAccount => _t('My Account', 'Hesabım');
  String get parentInfo => _t('Parent Info', 'Ebeveyn Bilgileri');
  String get firstName => _t('First Name', 'Ad');
  String get lastName => _t('Last Name', 'Soyad');
  String get language => _t('Language', 'Dil');
  String get english => _t('English', 'İngilizce');
  String get turkish => _t('Turkish', 'Türkçe');
  String get privacyPolicy => _t('Privacy Policy', 'Gizlilik Politikası');
  String get termsOfUse => _t('Terms of Use', 'Kullanım Şartları');
  String get supportAndFeedback =>
      _t('Support & Feedback', 'Destek & Geri Bildirim');
  String get deleteAccount => _t('Delete Account', 'Hesabımı Sil');
  String get version => _t('Version', 'Versiyon');
  String get editProfile => _t('Edit Profile', 'Profili Düzenle');
  String get subscription => _t('Subscription', 'Abonelik');
  String get currentPlan => _t('Current Plan', 'Mevcut Plan');
  String get freePlan => _t('Free', 'Ücretsiz');
  String get managePlan => _t('Manage Plan', 'Planı Yönet');
  String get logoutConfirm => _t('Are you sure you want to log out?',
      'Çıkış yapmak istediğinize emin misiniz?');
  String get cancel => _t('Cancel', 'İptal');
  String get confirm => _t('Onayla', 'Onayla');

  // ─── Subscription Screen ───
  String get subscriptionPlans => _t('Subscription Plans', 'Abonelik Planları');
  String get monthly => _t('Monthly', 'Aylık');
  String get yearly => _t('Yearly', 'Yıllık');
  String get savings => _t('Savings', 'Tasarruf');
  String get freeTrial => _t('7-Day Free Trial', '7 Günlük Ücretsiz Deneme');
  String get freeTrialDesc => _t(
      'Start now, pay nothing for the first 7 days. Cancel anytime.',
      'Hemen başlayın, ilk 7 gün hiçbir ücret ödemeyin. İstediğiniz zaman iptal edebilirsiniz.');
  String get premiumBenefits =>
      _t('Premium Benefits', 'Premium Üyelik Avantajları');
  String get unlimitedAI =>
      _t('Unlimited Patty Health Analysis', 'Sınırsız Patty Sağlık Analizi');
  String get unlimitedPets =>
      _t('Unlimited Pet Profiles', 'Sınırsız Pet Profili');
  String get pdfExport => _t('PDF Report Export', 'PDF Rapor Export');
  String get advancedAnalytics =>
      _t('Advanced Analytics Charts', 'Gelişmiş Analitik Grafikler');
  String get adFree => _t('Ad-Free Experience', 'Reklamsız Deneyim');
  String get priorityAI => _t('Priority Patty Processing', 'Öncelikli Patty İşleme');

  // ─── Log / Analysis ───
  String get analyzingPhoto =>
      _t('Analyzing photo...', 'Fotoğraf analiz ediliyor...');
  String get aiAnalysisSaved =>
      _t('Patty analysis saved.', 'Patty analizi kaydedildi.');
  String get selectVisibility => _t('Select visibility', 'Görünürlük seç');
  String get familyOnly => _t('Family members', 'Aile üyeleri');
  String get followersOnly => _t('Followers', 'Takipçiler');
  String get everyone => _t('Everyone', 'Herkes');
  String get healthReport =>
      _t('Detailed Health Report', 'Detaylı Sağlık Raporu');
  String get openHealthSummary =>
      _t('Open health summary', 'Sağlık özetini aç');
  String get careTip => _t('Care Tip', 'Bakım Tavsiyesi');
  String get petVoice => _t('Pet\'s Voice', 'Pet\'in Sesi');
  String get aiAnalysis => _t('AI Analysis', 'AI Analizi');
  String petSays(String petName) =>
      _t('$petName says', '$petName diyor ki');
  String get petVoiceLabelSetting => _t('Pet voice label', 'Pet sesi etiketi');
  String get petVoiceLabelPetSays => _t('"[Name] says"', '"[Ad] diyor ki"');
  String get petVoiceLabelPetVoice => _t('Pet\'s Voice', 'Pet\'in Sesi');
  String get petVoiceLabelAiAnalysis => _t('AI Analysis', 'AI Analizi');
  String get petVoiceLabelCustom => _t('Custom', 'Özel');
  String get petVoiceLabelCustomHint =>
      _t('Enter custom label', 'Özel etiket girin');
  String get parameters => _t('Parameters', 'Parametreler');
  String get trackedConditions =>
      _t('Tracked Conditions', 'Takip Edilen Durumlar');
  String dailyNote(String note) => _t('Daily Note: $note', 'Günlük Not: $note');
  String get photoLoadFailed =>
      _t('Photo could not be loaded', 'Fotoğraf yüklenemedi');
  String get noteSaved => _t('Note saved', 'Not kaydedildi');
  String get noteFailedSave =>
      _t('Note could not be saved', 'Not kaydedilemedi');

  // ─── Gamification ───
  String get achievements => _t('Achievements', 'Başarımlar');
  String get pointsShop => _t('Points Shop', 'Puan Marketi');
  String get gamification => _t('Gamification', 'Oyunlaştırma');
  String get viewAchievements =>
      _t('View Achievements', 'Başarımları Görüntüle');
  String get energyLevel => _t('Energy Level', 'Enerji Seviyesi');
  String energyPercent(int percent) =>
      _t('$percent% energy', '%$percent enerji');

  // ─── Errors / General ───
  String error(String msg) => _t('Error: $msg', 'Hata: $msg');
  String get continueAsGuest => _t('Continue as Guest', 'Misafir Olarak Devam Et');
  String get limitReached => _t('Limit Reached', 'Limit Doldu');
  String get upgradeToPremium => _t('Upgrade to Premium', 'Premium\'a Geç');
  String get premiumRequired => _t('Premium Required', 'Premium Gerekli');
  String get ok => _t('OK', 'Tamam');
  String get save => _t('Save', 'Kaydet');
  String get delete => _t('Delete', 'Sil');
  String get edit => _t('Edit', 'Düzenle');
  String get close => _t('Close', 'Kapat');
  String get loading => _t('Loading...', 'Yükleniyor...');
  String get noData => _t('No data', 'Veri yok');

  // ─── Upgrade / Limit dialog ───
  String get aiLimitReachedDialogTitle => _t('Limit Reached', 'Limit Doldu');
  String get aiLimitReachedDialogDesc => _t(
    'Your free Patty analysis limit for this month has been reached.\n\nUpgrade to Premium for unlimited analyses!',
    'Bu aydaki ücretsiz Patty analizi limitiniz doldu.\n\nPremium\'a geçerek sınırsız analiz yapabilirsiniz!',
  );
  String aiRemainingDialogDesc(int count) => _t(
    'You have $count free Patty analyses left this month.\n\nUpgrade to Premium for unlimited analyses!',
    'Bu ayda kalan ücretsiz Patty analizi: $count\n\nPremium\'a geçerek sınırsız analiz yapabilirsiniz!',
  );

  // ─── Analysis errors (user-facing) ───
  String get analysisFailed => _t(
    'Analysis could not be completed. Please try again.',
    'Analiz tamamlanamadı. Lütfen tekrar deneyin.',
  );
  String get apiKeyNotConfigured => _t(
    'Patty analysis is not configured. Please contact support.',
    'Patty analizi yapılandırılmamış. Lütfen destek ile iletişime geçin.',
  );

  // ─── Add Pet Screen ───
  String get addPet => _t('Add Pet', 'Pet Ekle');
  String get petName => _t('Pet Name', 'Pet Adı');
  String get petType => _t('Pet Type', 'Pet Türü');
  String get breed => _t('Breed', 'Cins');
  String get selectPhoto => _t('Select Photo', 'Fotoğraf Seç');

  // ─── Premium Paywall (new) ───
  String aiRemaining(int count) => _t('$count Patty analyses left this month',
      'Bu ay $count Patty analiz hakkınız kaldı');
  String get aiLimitReached => _t('Monthly Patty analysis limit reached',
      'Aylık Patty analiz limitinize ulaştınız');
  String get premiumUnlock => _t('Unlock with Premium', 'Premium ile Aç');
  String get currentPlanLabel => _t('Current Plan', 'Mevcut Plan');
  String get maxPetsReached => _t(
      'You can add only 1 pet on the free plan. Upgrade to Premium for unlimited pets!',
      'Ücretsiz planda sadece 1 pet ekleyebilirsiniz. Sınırsız pet için Premium\'a geçin!');
  String get aiTaskSuggestions =>
      _t('Patty Task Suggestions', 'Patty Görev Önerileri');
  String get aiTaskSuggestionsDesc => _t(
      'Get smart care suggestions from Patty with Premium.',
      'Premium ile Patty\'dan akıllı bakım önerileri alın.');

  String get healthRadarTitle => _t('Health Radar', 'Sağlık Özeti');
  String get healthRadarDescription => _t(
      'See your pet\'s health balance across all parameters.',
      'Dostunun tüm parametrelerdeki sağlık dengesini gör.');
  String get advancedAiInsightsTitle =>
      _t('Advanced AI Insights', 'İleri AI Analizleri');
  String get advancedAiInsightsDescription => _t(
      'Get deep patterns and health predictions with AI.',
      'AI ile derin desenler ve sağlık tahminleri al.');
  String get moodEnergyTrendDescription => _t(
      'See detailed mood and energy charts with Premium.',
      'Premium ile detaylı mood ve enerji grafikleri gör.');
  String get healthVitalsDescription => _t(
      'Unlock detailed health metrics with Premium.',
      'Premium ile detaylı sağlık metriklerini aç.');

  // ─── Helpers ───
  String _t(String en, String tr) {
    return languageCode == 'en' ? en : tr;
  }
}

/// Returns the label for the pet voice / AI analysis card based on user preference.
String getPetVoiceLabel(BuildContext context, String? petName) {
  final loc = context.read<LocaleProvider>();
  final s = S.of(context);
  if (loc.petVoiceLabelStyle == LocaleProvider.petVoiceStyleCustom &&
      (loc.petVoiceLabelCustom ?? '').trim().isNotEmpty) {
    return loc.petVoiceLabelCustom!.trim();
  }
  if (loc.petVoiceLabelStyle == LocaleProvider.petVoiceStyleAiAnalysis) {
    return s.aiAnalysis;
  }
  if (loc.petVoiceLabelStyle == LocaleProvider.petVoiceStylePetVoice) {
    return s.petVoice;
  }
  return s.petSays(petName ?? 'Pet');
}
