# PetAI – App Store Yayın Planı (Son Plan)

Bu dokümanda **RevenueCat**, **Gemini API**, mağaza gereksinimleri ve build süreci tek bir planda toplanmıştır. Adımları sırayla tamamlayarak uygulamayı App Store’da yayınlayabilirsiniz.

---

## Genel Bakış

| Bileşen | Mevcut Durum | Yapılacak |
|--------|----------------|-----------|
| **RevenueCat** | Kod entegre (`purchases_flutter`), API key placeholder | Gerçek key’ler, App Store Connect ürünleri, test |
| **Gemini API** | Client’ta `--dart-define=GEMINI_API_KEY` | İlk yayın: dart-define; isteğe bağlı: Edge Function |
| **Bundle ID** | `com.example.petAi` | Gerçek bundle ID (Apple reddeder) |
| **Gizlilik / Kullanım** | Placeholder | Privacy Policy + Terms URL’leri |
| **Supabase Edge Functions** | Yok | İsteğe bağlı: Gemini’yi backend’e taşımak için |

---

## Faz 1 – Mağaza ve Kimlik Hazırlığı

### 1.1 Apple Developer & App Store Connect

- [ ] **Apple Developer Program** üyeliği aktif (yıllık ücret).
- [ ] **App Store Connect** → My Apps → yeni uygulama oluştur.
- [ ] **Bundle ID**: `com.example.petAi` kullanılmamalı. Örnek: `com.sirketadiniz.petai` veya `com.adiniz.petai`.
  - Değişiklik: `ios/Runner.xcodeproj/project.pbxproj` içinde tüm `PRODUCT_BUNDLE_IDENTIFIER = com.example.petAi` satırlarını yeni bundle ID ile değiştir.
  - RunnerTests için: `com.example.petAi.RunnerTests` → `com.sirketadiniz.petai.RunnerTests`.
- [ ] App Store Connect’te bu bundle ID ile **App ID** oluşturuldu.

### 1.2 Uygulama Bilgileri (App Store Connect)

- [ ] **App adı**: PetPal (veya nihai isim).
- [ ] **Kategori**: Health & Fitness veya Lifestyle.
- [ ] **Age rating**: Anket dolduruldu.
- [ ] **Privacy Policy URL**: Canlı bir sayfa (zorunlu).
- [ ] **Support URL**: Destek e-posta veya web sayfası.
- [ ] **Keywords** ve **Açıklama** (TR/EN): Yazıldı.

### 1.3 Gizlilik ve Kullanım Şartları

- [ ] **Gizlilik Politikası** sayfası yayında (web / GitHub Pages / Notion vb.).
- [ ] **Kullanım Şartları** sayfası yayında.
- [ ] Her iki URL hem **App Store Connect** hem de **uygulama içi** (Settings) ekranında kullanılıyor.
- Projede Settings’te bu linklerin gerçek URL’lere güncellenmesi gerekir (şu an placeholder olabilir).

---

## Faz 2 – RevenueCat Entegrasyonu

### 2.1 RevenueCat Hesabı

- [ ] [RevenueCat](https://www.revenuecat.com) hesabı açıldı.
- [ ] Yeni **Project** oluşturuldu.
- [ ] **iOS App** eklendi (Bundle ID, App Store Connect ile eşleşmeli).
- [ ] İsteğe bağlı: **Android App** eklendi (Play Store yayını için).

### 2.2 App Store Connect’te Abonelik Ürünleri

- [ ] App Store Connect → Uygulama → **In-App Purchases** → **Subscriptions**.
- [ ] **Subscription Group** oluşturuldu (örn. “Premium”).
- [ ] En az bir **auto-renewable subscription** tanımlandı, örnekler:
  - Aylık: `premium_monthly` (veya RevenueCat’te kullanacağınız product ID).
  - Yıllık: `premium_yearly` (veya `premium_annual`).
- [ ] Fiyatlar ve deneme süresi (varsa) ayarlandı.
- [ ] **Shared Secret** (App Store Connect → App → App Information) kopyalandı ve RevenueCat’te ilgili iOS app’e eklendi.

### 2.3 RevenueCat’te Yapılandırma

- [ ] **Products**: RevenueCat’te aynı product ID’ler (örn. `premium_monthly`, `premium_yearly`) tanımlandı.
- [ ] **Entitlements**: Bir entitlement oluşturuldu (örn. `premium`). Bu entitlement, uygulama tarafında “abone mi?” kontrolü için kullanılacak.
- [ ] **Offerings**: Varsayılan offering’te paketler (monthly / yearly) eklendi.
- [ ] **API Keys**: RevenueCat Dashboard → Project Settings → API Keys:
  - **iOS** (Public app-specific key) kopyalandı.
  - **Android** (Play Store kullanılacaksa) kopyalandı.

### 2.4 Uygulamada API Key’leri (Güvenli Yöntem)

Anahtarları **koda sabit yazmayın**. Aşağıdaki yöntemlerden biri kullanılmalı:

**Yöntem A – Build-time (dart-define)**  
- `PurchaseService` içindeki sabit key’ler kaldırılır; değerler `String.fromEnvironment('REVENUECAT_IOS_API_KEY', defaultValue: '')` ve Android için benzeri ile alınır.
- Build:
  - iOS:  
    `flutter build ios --dart-define=REVENUECAT_IOS_API_KEY=appl_xxxxx`
  - Android:  
    `flutter build appbundle --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxxxx`
- CI/CD’de bu değişkenler **secrets** olarak saklanır.

**Yöntem B – Dosyadan (git’e eklenmeyen)**  
- Proje kökünde `env.json` (veya `env.release.json`) oluşturulur, `.gitignore`’a eklenir.
- İçerik örnek:  
  `{"REVENUECAT_IOS_API_KEY": "appl_xxx", "REVENUECAT_ANDROID_API_KEY": "goog_xxx"}`
- Build:  
  `flutter build ios --dart-define-from-file=env.json`

Yapılacak kod değişikliği özeti:

- `lib/services/purchase_service.dart`:
  - `_revenueCatApiKeyIOS` ve `_revenueCatApiKeyAndroid` yerine `String.fromEnvironment('REVENUECAT_IOS_API_KEY', defaultValue: '')` ve `String.fromEnvironment('REVENUECAT_ANDROID_API_KEY', defaultValue: '')` kullanın.
  - `_hasConfiguredKeys` bu değerlerin `YOUR_REVENUECAT_` ile başlamamasına göre güncellenir.

### 2.5 Entitlement Kontrolü ve Supabase

- [ ] Uygulama, abonelik durumunu RevenueCat’ten (`CustomerInfo`, `entitlements.active`) okuyor — mevcut kod bunu yapıyor.
- [ ] Supabase `user_subscriptions` güncellemesi satın alma / restore sonrası çalışıyor — `_updateSubscriptionAfterPurchase` mevcut.
- [ ] RevenueCat’teki **product identifier** ile Supabase `subscription_plans.name` eşleşmeli (örn. `premium_monthly` → plan adı `premium`; `_extractPlanNameFromProductId` buna göre).

### 2.6 Test

- [ ] **Sandbox tester** (App Store Connect → Users and Access → Sandbox) oluşturuldu.
- [ ] Gerçek cihazda (Simulator değil) uygulama çalıştırıldı, abonelik ekranından satın alma denendi.
- [ ] Restore purchases test edildi.
- [ ] RevenueCat Dashboard’da event’ler görülüyor.

---

## Faz 3 – Gemini API Entegrasyonu

İki seçenek: **A – Client’ta anahtar** (hızlı, ilk yayın) veya **B – Backend (Edge Function)** (daha güvenli, önerilen uzun vadede).

### 3.1 Seçenek A – Client’ta API Anahtarı (İlk Yayın)

- [ ] **Google AI Studio** veya **Google Cloud Console** üzerinden Gemini API anahtarı alındı.
- [ ] Anahtar **hiçbir zaman** repoya veya public yere yazılmıyor.
- [ ] Build komutları:
  - iOS:  
    `flutter build ios --dart-define=GEMINI_API_KEY=AIzaSy...`
  - Android:  
    `flutter build appbundle --dart-define=GEMINI_API_KEY=AIzaSy...`
- [ ] İsteğe bağlı: `env.json` kullanımı (DEPLOY_APP_STORE.md’deki gibi):  
  `flutter build ios --dart-define-from-file=env.json`  
  (`env.json` içinde `GEMINI_API_KEY` olabilir; dosya `.gitignore`’da olmalı.)
- [ ] Mevcut `AppConfig.geminiApiKey` zaten `String.fromEnvironment('GEMINI_API_KEY', defaultValue: '')` kullanıyor; ek değişiklik gerekmez.

**Risk**: Uygulama decompile edilirse anahtar çıkarılabilir; kullanım limiti / kötüye kullanım mümkündür. İlk yayın ve düşük trafik için kabul edilebilir.

### 3.2 Seçenek B – Backend (Supabase Edge Function) – Önerilen Uzun Vadede

- [ ] **Supabase Dashboard** → Edge Functions → yeni function (örn. `analyze-pet`).
- [ ] **Secret**: `GEMINI_API_KEY` Supabase project secrets’a eklendi.
- [ ] Function:
  - Auth ile gelen isteği doğrular (JWT / Supabase auth).
  - Gövdeden fotoğraf (base64) ve parametreleri alır.
  - Gemini API’yi **sunucuda** çağırır (Node/Deno ile `google-generative-ai` veya REST).
  - Aynı JSON çıktıyı (summary_tr, care_tip_tr, pet_voice_tr, skorlar vb.) döndürür.
- [ ] **Flutter**: `AIService.analyzePetPhoto` (ve gerekirse `detectPetIdentity`) bu Edge Function’a HTTP isteği atacak şekilde değiştirilir. API anahtarı artık uygulamada olmaz.
- [ ] Rate limit / maliyet kontrolü istenirse Edge Function veya Supabase üzerinde eklenebilir.

Bu geçiş için ayrı bir görev planı (Edge Function iskeleti + Flutter tarafı refactor) oluşturulabilir; ilk yayında Seçenek A yeterli.

---

## Faz 4 – Build ve Yükleme

### 4.1 Ortam Dosyası (Önerilen)

Proje kökünde **`.gitignore`’a eklenmiş** bir dosya, örnek: `env.release.json`. Örnek format için `env.release.example.json` kullanılabilir (gerçek değerler yazılmaz, repoda kalır).

```json
{
  "GEMINI_API_KEY": "AIzaSy...",
  "REVENUECAT_IOS_API_KEY": "appl_...",
  "REVENUECAT_ANDROID_API_KEY": "goog_..."
}
```

Build:

- iOS:  
  `flutter build ios --release --dart-define-from-file=env.release.json`
- Android:  
  `flutter build appbundle --release --dart-define-from-file=env.release.json`

### 4.2 iOS Archive ve App Store’a Gönderme

1. [ ] `flutter build ios --release --dart-define-from-file=env.release.json` (veya yukarıdaki dart-define’lar).
2. [ ] `open ios/Runner.xcworkspace` → Xcode’da **Product → Archive**.
3. [ ] **Distribute App** → App Store Connect → Upload.
4. [ ] App Store Connect’te build seçilip versiyon gönderildi.

### 4.3 TestFlight

- [ ] Build yüklendikten sonra **TestFlight** sekmesinde görünüyor.
- [ ] Internal / External test gruplarına dağıtıldı.
- [ ] En az bir gerçek cihazda (RevenueCat + Gemini dahil) test edildi.

---

## Faz 5 – CI/CD (İsteğe Bağlı)

- [ ] GitHub Actions / Codemagic / Fastlane vb. kullanılacaksa:
  - `GEMINI_API_KEY`, `REVENUECAT_IOS_API_KEY`, `REVENUECAT_ANDROID_API_KEY` **repository secrets** (veya CI ortam değişkenleri) olarak tanımlandı.
  - Build adımında:
    - `flutter build ios --release --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }} --dart-define=REVENUECAT_IOS_API_KEY=${{ secrets.REVENUECAT_IOS_API_KEY }}`
    - Android için aynı mantıkla `REVENUECAT_ANDROID_API_KEY` ve `GEMINI_API_KEY` verilir.
- [ ] Archive ve upload otomasyonu (örn. Fastlane) isteğe bağlı eklenir.

---

## Kontrol Listesi – Yayın Öncesi Son Kontrol

### Kod ve Yapılandırma

- [ ] Bundle ID `com.example.petAi` değil; gerçek bundle ID kullanılıyor.
- [ ] RevenueCat API key’leri ortam değişkeni / dart-define ile veriliyor; kodda sabit placeholder yok.
- [ ] Gemini API key build-time’da veriliyor (veya Edge Function kullanılıyor).
- [ ] Privacy Policy ve Terms URL’leri hem mağaza hem uygulama içinde doğru.

### Mağaza

- [ ] App Store Connect’te uygulama oluşturuldu, screenshot’lar (5.5", 6.5", 6.7") yüklendi.
- [ ] In-App Purchase subscription ürünleri “Ready to Submit”.
- [ ] RevenueCat’te iOS (ve Android) app bağlı, entitlement ve offering’ler doğru.

### Test

- [ ] Sandbox ile satın alma ve restore çalışıyor.
- [ ] AI analizi (Gemini) gerçek cihazda çalışıyor.
- [ ] Kritik akışlar (kayıt, giriş, pet ekleme, log, abonelik) TestFlight’ta test edildi.

### Güvenlik

- [ ] `env.release.json` (veya benzeri) `.gitignore`’da; repoda yok.
- [ ] CI’da kullanılan secret’lar güvenli şekilde saklanıyor.

---

## Özet Sıra

1. **Faz 1**: Bundle ID, Apple/Google hesap, mağaza bilgileri, Privacy/Terms URL’leri.
2. **Faz 2**: RevenueCat hesap, App Store Connect abonelik ürünleri, RevenueCat’te entitlement/offering, uygulamada key’leri dart-define/env ile verme, test.
3. **Faz 3**: Gemini için ya dart-define ile build (Seçenek A) ya da Edge Function (Seçenek B) planı.
4. **Faz 4**: Tek komutla release build (env.release.json veya dart-define), Archive, upload, TestFlight.
5. **Faz 5**: İsteğe bağlı CI/CD ve otomasyon.

Bu plan tamamlandığında uygulama **RevenueCat abonelikleri** ve **Gemini API** ile App Store’da yayına hazır olacaktır. İlk yayın için Seçenek A (client’ta Gemini key) yeterli; trafik ve güvenlik ihtiyacı arttıkça Seçenek B’ye geçilmesi önerilir.
