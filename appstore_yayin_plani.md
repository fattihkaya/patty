# 🐾 Patty — App Store Yayın Planı

Bu dosya, **Patty** uygulamasının App Store'a (iOS) sorunsuz bir şekilde yüklenmesi için gereken tüm teknik ve idari adımları içerir.

---

## FAZA 1 — Hazırlık & Temizlik ✅
> _Uygulamayı "Release" moduna hazır hale getirdik._

### Adım 1: Gereksiz Dosyaların Temizlenmesi ✅
- [x] Tüm unused importlar temizlendi.
- [x] Kullanılmayan assetler ve boş klasörler (`finance/`, `tasks/`) temizlendi.

### Adım 2: Boş Sayfaların Kaldırılması ✅
- [x] Boş modüller navigation bar'dan ve router'dan kaldırıldı.

### Adım 3: Lint Issues (Kod Kalitesi) ✅
- [x] `flutter analyze` sonuçlarındaki 56+ kritik uyarı (const usage, context synchronous usage vb.) giderildi.

---

## FAZA 2 — Güvenlik & Konfigürasyon ✅
> _Hassas verileri koda gömülü olmaktan çıkardık._

### Adım 4: Build Config Sınıfı ✅
- [x] `String.fromEnvironment` kullanılarak API Key'lerin build anında alınması sağlandı (`AppConfig` sınıfı).

### Adım 5: Supabase Key Security ✅
- [x] `supabase_config.dart`'taki hardcoded anon key → `String.fromEnvironment` ile taşındı.
- [x] Güvenli konfigürasyon altyapısı kuruldu (SUPABASE_URL, SUPABASE_ANON_KEY).

### Adım 6: Gemini API Key Doğrulaması ✅
- [x] Production Gemini API key altyapısı hazır (`AppConfig.geminiApiKey`).
- [x] `env.release.json.example` şablonu oluşturuldu.

### Adım 7: Supabase RLS (Row Level Security) Kontrolü 🚨
> **Kritik:** Verilerin korunması için tablolarda RLS açık olmalı. Lütfen Dashboard'da doğrula:
- [ ] `profiles`, `pets`, `daily_logs`, `expenses`, `pet_members` tablolarında RLS aktif mi?

---

## FAZA 3 — iOS Konfigürasyonu ✅
> _İkonlar, açılış ekranları ve izinler hazır._

### Adım 8: Info.plist Güncellemeleri ✅
- [x] İzin açıklamaları (Kamera, Galeri) profesyonelce (TR/EN) eklendi.
- [x] `ITSAppUsesNonExemptEncryption` ve `CFBundleAllowMixedLocalizations` eklendi.

### Adım 9: App Icon ✅

- [x] "Patty" temalı enerjik gradyan tasarım seçildi.
- [x] `flutter_launcher_icons` ile tüm boyutlar üretildi. (Arka plan Slate 900 ile optimize edildi ✨)

### Adım 10: Launch Screen (Splash) ✅

- [x] Patty logolu, koyu temalı profesyonel açılış ekranı oluşturuldu.
- [x] Beyaz çerçeve sorunu giderildi, temiz logo tasarımı uygulandı. ✅

---

## FAZA 4 — Yasal Gereksinimler ✅
> _Apple'ın zorunlu kıldığı yasal sayfalar ve destek linkleri._

### Adım 11: Gizlilik Politikası (Privacy Policy) ✅
- [x] <https://sites.google.com/view/privacy-policy-patty>
- [x] Uygulamaya bağlandı.

### Adım 12: Kullanım Şartları (Terms of Use) ✅

- [x] <https://sites.google.com/view/terms-of-use-patty>
- [x] Uygulamaya bağlandı (EULA dahil).

### Adım 13: Destek & İletişim URL ✅

- [x] <https://sites.google.com/view/patty-page/>
- [x] Ayarlar menüsüne eklendi.

---

## FAZA 5 — Monetizasyon & RevenueCat ✅
> _Gelir modeli ve abonelik sistemi._

### Adım 14: RevenueCat Kurulumu ✅

- [x] Patty için proje oluşturuldu.
- [x] API Key `test_SXWIZWCwCzlcrCZtvzmsbMOSgGF` bağlandı.
- [x] `purchases_ui_flutter` entegrasyonu tamamlandı (Paywalls & Customer Center).

### Adım 15: Abonelik Ürünleri ✅

- [x] `monthly`, `yearly`, `lifetime` ürünleri tanımlandı.
- [x] "Patty Pro" entitlement (hak tanımlama) bağlandı.
- [x] `PurchaseService` üzerinden otomatik Supabase senkronizasyonu kuruldu.

---

## FAZA 6 — App Store Connect & İnceleme ⏳

### Adım 16: Screenshot'ları Hazırla ✅

- [x] Sosyal topluluk ve keşfet akışı vizyonu belirlendi (Görsel 3 seçildi).
- [x] "AI Analiz", "Paylaşım" ve "Topluluk" görselleri üretildi.
- [ ] iPhone 6.7" ve 6.5" boyutları için nihai çıktıların alınması.

### Adım 17: Uygulama Kaydı Oluştur ⏳

- [ ] <https://appstoreconnect.apple.com> üzerinden "Patty" kaydını aç.
- [x] Bundle ID: `com.patty.app` olarak hem iOS hem Android tarafında güncellendi. ✅
- [ ] Uygulama açıklamasını (Description) "Sosyal Evcil Hayvan Günlüğü" odaklı hazırla.
