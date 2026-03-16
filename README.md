# Patty (PetAI)

AI destekli evcil hayvan takip uygulaması. Flutter ve Supabase ile geliştirilmiştir.

## Özellikler

- **Pet profilleri** — Birden fazla evcil hayvan ekleme ve yönetme
- **AI analiz** — Pet fotoğrafından Google Gemini ile tür, ırk ve öneri analizi
- **Görevler & takvim** — Pet görevleri, hatırlatıcılar, aşı takvimi
- **Sosyal** — Hikayeler, keşfet, liderlik tablosu
- **Sağlık & giderler** — Sağlık parametreleri, masraf kategorileri
- **Gamification** — Rozetler, puan dükkanı, streak kutlamaları
- **Abonelik** — Premium özellikler (In-App Purchase)
- **Çoklu dil** — Yerelleştirme desteği

## Teknolojiler

- **Flutter** — Cross-platform (Android, iOS, Web, Windows)
- **Supabase** — Auth, veritabanı, gerçek zamanlı
- **Google Gemini API** — Pet fotoğrafı analizi
- **Provider** — State management

## Gereksinimler

- Flutter SDK (>=3.0.0)
- Supabase projesi
- (Opsiyonel) Gemini API anahtarı — pet analizi için

## Kurulum

### 1. Bağımlılıklar

```bash
flutter pub get
```

### 2. Ortam dosyaları

Proje kökünde `env.json` oluştur (veya `env.json.example` dosyasını kopyalayıp düzenle):

```json
{
  "SUPABASE_URL": "https://xxx.supabase.co",
  "SUPABASE_ANON_KEY": "your_anon_key"
}
```

Release build için `env.release.json` kullanılır; örnek: `env.release.json.example`.

**Not:** `env.json` ve `env.release.json` `.gitignore`'da; anahtarlar repoya gönderilmez.

### 3. Çalıştırma

**Geliştirme (AI analizi dahil):**

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

**Sadece çalıştırma (Gemini anahtarı olmadan):**

```bash
flutter run
```

Uygulama açılır; Gemini anahtarı yoksa analiz ekranında yapılandırma uyarısı gösterilir.

**Release build (ör. Android APK):**

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key
```

## Proje yapısı

| Klasör / dosya | Açıklama |
|----------------|----------|
| `lib/` | Kaynak kod (ekranlar, servisler, modeller, provider’lar) |
| `lib/core/` | Tema, config, sabitler, Supabase config |
| `lib/screens/` | Ana ekranlar (auth, home, pet, profile, subscription, vb.) |
| `lib/services/` | AI, bildirim, satın alma, hatırlatıcı servisleri |
| `supabase/` | Veritabanı migration ve şema dosyaları |
| `env.json.example` | Supabase env örneği |

## Dokümantasyon

- [App Store yayın planı](APP_STORE_RELEASE_PLAN.md)
- [Deploy rehberi](DEPLOY_APP_STORE.md)
- Diğer planlama ve analiz dokümanları proje kökündeki `.md` dosyalarında.

## Lisans

Bu proje publish_to: "none" ile yapılandırılmıştır; kullanım koşulları proje sahibine aittir.
