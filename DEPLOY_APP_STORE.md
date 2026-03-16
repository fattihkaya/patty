# App Store / Play Store’da Yayınlarken API Anahtarı

İki yol var: **hızlı (anahtar uygulama içinde)** veya **güvenli (backend üzerinden)**.

---

## Seçenek A: Build sırasında anahtar vermek (hızlı)

Anahtar, uygulama ikilisine gömülür. **Risk:** Uygulama decompile edilirse anahtar çıkarılabilir; kullanım limiti/abuse riski vardır. Küçük projeler veya ilk yayın için kullanılabilir.

### iOS (App Store)

1. **Terminalden build alın** (anahtarı burada verin; komutu kimseyle paylaşmayın):

   ```bash
   flutter build ios --dart-define=GEMINI_API_KEY=AIzaSy...sizin_anahtar
   ```

2. **Xcode ile archive:**

   - `open ios/Runner.xcworkspace`
   - Product → Archive
   - Distribute App → App Store Connect

Build’i hep yukarıdaki `flutter build ios ...` komutuyla alın. Xcode’u doğrudan “Run” ile çalıştırırsanız anahtar gömülü olmaz.

**CI/CD (GitHub Actions / Codemagic vb.):**  
`GEMINI_API_KEY`’i **repository secrets**’a ekleyin; build komutunda kullanın:

   ```yaml
   - run: flutter build ios --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}
   ```

### Android (Play Store)

```bash
flutter build appbundle --dart-define=GEMINI_API_KEY=AIzaSy...sizin_anahtar
```

CI’da da aynı şekilde `secrets.GEMINI_API_KEY` ile verin.

### Anahtarı dosyada tutmak (isteğe bağlı)

Anahtarı kodda veya komutta göstermemek için:

1. Proje kökünde (ve **.gitignore**’da olan) bir dosya oluşturun, örn. `env.json`:

   ```json
   {
     "GEMINI_API_KEY": "AIzaSy...sizin_anahtar"
   }
   ```

2. Build’de şunu kullanın:

   ```bash
   flutter build ios --dart-define-from-file=env.json
   flutter build appbundle --dart-define-from-file=env.json
   ```

`.gitignore`’a mutlaka ekleyin: `env.json`

---

## Seçenek B: Backend üzerinden (önerilen, güvenli)

API anahtarı **sadece sunucuda** durur; uygulama sadece kendi backend’inize istek atar. Supabase kullandığınız için **Supabase Edge Function** ile yapmak en pratik yol.

### Genel akış

1. Uygulama: Fotoğraf + parametreleri **Supabase Edge Function**’a gönderir (Supabase auth ile korunur).
2. Edge Function: Gemini API’yi **sunucu tarafında** çağırır (anahtar Supabase secret’ta).
3. Sonuç uygulama tarafına döner; anahtar hiçbir zaman uygulamada olmaz.

### Adımlar (kısa)

1. **Supabase Dashboard** → Edge Functions → yeni function (örn. `analyze-pet`).
2. **Secrets:** `GEMINI_API_KEY` değerini Supabase’e secret olarak ekleyin.
3. Function içinde: gelen isteği doğrulayın, Gemini’ye fotoğraf + prompt gönderin, JSON cevabını döndürün.
4. **Flutter:** `AIService`’i bu function’ın URL’ini çağıracak şekilde güncelleyin (veya `AppConfig`’e backend URL ekleyip oradan kullanın).

Bu projede Seçenek B için örnek bir Edge Function iskeleti ve uygulama tarafında nasıl kullanılacağı `supabase/functions/` ve `lib/core/app_config.dart` / `lib/services/ai_service.dart` içinde not edilebilir veya eklenebilir.

---

## Özet

| Yöntem              | Güvenlik | Kurulum      | Öneri              |
|---------------------|----------|-------------|--------------------|
| A: --dart-define    | Orta     | Kolay       | İlk yayın / test   |
| B: Edge Function    | Yüksek   | Biraz iş    | Uzun vadede tercih |

İlk kez yayınlıyorsanız **Seçenek A** ile çıkıp, sonra **Seçenek B**’ye geçebilirsiniz. Geçişte uygulama sadece API’yi nereden çağırdığını değiştirir; kullanıcı akışı aynı kalır.
