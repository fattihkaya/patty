# pet_ai

AI-powered pet tracking application (PetPal) with Supabase backend.

## Getting Started

### PetPal (AI) analiz için API anahtarı

Pet fotoğrafı analizi Google Gemini API kullanır. Anahtar kaynak kodda tutulmaz; çalıştırırken verilmelidir:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key_here
```

Release build (ör. Android APK): `flutter build apk --dart-define=GEMINI_API_KEY=your_key`

Anahtar verilmezse uygulama açılır ancak analiz ekranında yapılandırma uyarısı gösterilir.

---

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
