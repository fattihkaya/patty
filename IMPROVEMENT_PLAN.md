# PetAI (PetPal) İyileştirme Planı

Bu doküman tasarım iyileştirmeleri ve kritik düzeltmeler için yol haritasıdır.

---

## Faz 1: Kritik Düzeltmeler ✅

### 1.1 API Anahtarı Güvenliği
- **Sorun:** Gemini API anahtarı `AIService` içinde sabit kodlanmış.
- **Çözüm:** `lib/core/app_config.dart` ile `--dart-define=GEMINI_API_KEY=...` kullanımı.
- **Sonuç:** Anahtar kaynak kodda tutulmaz; CI/CD veya lokal çalıştırmada verilir.

### 1.2 Kullanıcıya Gösterilen Hata Mesajları
- **Sorun:** "Hata: $e" gibi ham exception kullanıcıya gösteriliyor.
- **Çözüm:** Genel hata metni (`analysisFailed`, `somethingWentWrong`) + gerektiğinde log.

### 1.3 Upgrade Dialog Lokalizasyonu
- **Sorun:** Premium limit dialog’undaki açıklama metni sabit Türkçe.
- **Çözüm:** `app_strings.dart` içine `aiLimitReachedDesc`, `aiRemainingDesc` eklenip dialog’da `S.of(context)` kullanımı.

---

## Faz 2: Tasarım İyileştirmeleri ✅

### 2.1 Dark Mode
- **Sorun:** Sadece light tema var.
- **Çözüm:** `AppTheme.darkTheme` eklendi; sistem tercihine göre `themeMode` (veya ayarlardan seçim) ile kullanım.

### 2.2 Giriş Ekranı Gradient Uyumu
- **Sorun:** Login gradient renkleri `constants.dart` paletiyle aynı değil.
- **Çözüm:** Gradient `AppConstants` içindeki mevcut renklerle (örn. `subtleGradient`, `primaryLight`) tanımlandı veya theme ile uyumlu hale getirildi.

### 2.3 Tema Modu Tercihi (Opsiyonel)
- Ayarlar ekranına "Karanlık mod" / "Sistemle uyumlu" seçeneği eklenebilir; state `LocaleProvider` benzeri bir `ThemeProvider` veya mevcut provider’da tutulur.

---

## Faz 3: İleride Yapılabilecekler

| Öğe | Açıklama |
|-----|----------|
| **AI analiz ilerleme** | "Analiz yapılıyor..." yerine progress veya adım göstergesi |
| **Offline / cache** | Analiz sonuçları ve timeline için basit offline destek |
| **Supabase anahtarları** | URL ve anon key için de `--dart-define` veya backend proxy |
| **Erişilebilirlik** | Semantik label’lar, kontrast oranları, font ölçekleme |

---

## Çalıştırma (API anahtarı ile)

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

Android release:
```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key
```

Anahtar verilmezse AI analiz ekranında "API yapılandırılmadı" benzeri kullanıcı mesajı gösterilir.

---

## Dosya Değişiklikleri Özeti

| Dosya | Değişiklik |
|-------|------------|
| `lib/core/app_config.dart` | **Yeni** – API key `--dart-define=GEMINI_API_KEY` ile okunur |
| `lib/core/theme.dart` | Dark theme eklendi (`AppTheme.darkTheme`) |
| `lib/core/constants.dart` | Dark palette + `loginScreenGradient` eklendi |
| `lib/core/app_strings.dart` | Upgrade dialog ve analiz hata metinleri (TR/EN) |
| `lib/main.dart` | `darkTheme`, `themeMode: ThemeMode.system` eklendi |
| `lib/services/ai_service.dart` | `AppConfig.geminiApiKey` kullanımı; anahtar yoksa StateError |
| `lib/screens/main_container.dart` | Lokalize metinler, kullanıcı dostu hata, dark-aware bottom bar |
| `lib/screens/auth/login_screen.dart` | `loginScreenGradient` + dark mode arka plan |
