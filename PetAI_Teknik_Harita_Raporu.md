# PetAI - Teknik Harita ve İşleyiş Mantığı Raporu

**Hazırlayan:** Senior Software Architect  
**Tarih:** 12 Ocak 2026  
**Yöntem:** Codebase detaylı analizi (varsayım yapılmamış, sadece mevcut kodlara dayalı)

---

## 1. PROJENİN AMACI

### Temel Hizmet
**PetAI**, evcil hayvan sahipleri için **AI destekli sağlık takip ve bakım yönetim platformu**dur.

### Ana Value Proposition
- **AI-Powered Health Analysis**: Google Gemini 2.5 Pro ile pet fotoğraflarından 10 parametreli biyometrik sağlık analizi
- **Comprehensive Health Tracking**: Günlük log kayıtları, kronik durum takibi, sağlık trend grafikleri
- **Multi-Pet Management**: Birden fazla pet profili yönetimi
- **Family Sharing**: Pet'leri aile üyeleriyle paylaşma (owner/editor/viewer rolleri)
- **Task Management**: Pet tipine özel görevler ve otomatik hatırlatmalar
- **Financial Management**: Harcama takibi, mama stok yönetimi, tekrarlayan giderler
- **Social Features**: Log beğenileri, liderlik tablosu, sosyal etkileşim
- **Gamification**: Pati puanları, streak takibi, görev tamamlama sistemi

### Hedef Kullanıcı
Evcil hayvan sahipleri, özellikle köpek ve kedi sahipleri. Uygulama Türkçe dilinde, yerel kullanıcıya yönelik tasarlanmış.

---

## 2. TEKNİK STACK VE MİMARİ

### Teknoloji Stack

#### Frontend
- **Framework**: Flutter 3.0+ (Dart SDK >=3.0.0)
- **Platform Desteği**: Android, iOS, Web
- **State Management**: **Provider Pattern** (`provider: ^6.1.2`)
- **UI Kütüphaneleri**:
  - `google_fonts: ^6.2.1` - Tipografi
  - `flutter_animate: ^4.5.0` - Animasyonlar
  - `fl_chart: ^0.66.0` - Grafikler
  - `syncfusion_flutter_charts: 32.1.22` - Gelişmiş grafikler
  - `table_calendar: ^3.2.0` - Takvim widget'ı
  - `shimmer: ^3.0.0` - Loading efektleri

#### Backend
- **BaaS (Backend as a Service)**: **Supabase** (`supabase_flutter: ^2.12.0`)
  - PostgreSQL veritabanı
  - Row Level Security (RLS) ile güvenlik
  - Storage (fotoğraf yükleme için)
  - Authentication (email/password)

#### AI Integration
- **Google Generative AI** (`google_generative_ai: ^0.4.7`)
  - Model: `gemini-2.5-pro`
  - Vision capabilities (fotoğraf analizi)

#### Diğer Kütüphaneler
- `image_picker: ^1.0.7` - Fotoğraf seçimi
- `shared_preferences: ^2.2.2` - Lokal depolama
- `flutter_local_notifications: ^17.2.3` - Push bildirimleri
- `timezone: ^0.9.4` - Zaman dilimi yönetimi
- `intl: ^0.20.2` - Tarih/saat formatlama
- `share_plus: ^7.2.2` - Paylaşım özelliği

### Mimari Desen

#### Yapı: **Layered Architecture (Katmanlı Mimari)**

```
lib/
├── core/                    # Konfigürasyon ve sabitler
│   ├── constants.dart       # UI sabitleri (renkler, spacing, shadows)
│   ├── theme.dart           # Material tema tanımları
│   ├── supabase_config.dart # Supabase bağlantı konfigürasyonu
│   └── health_parameters.dart # Sağlık parametreleri tanımları
├── models/                  # Veri modelleri (Domain Layer)
│   ├── pet_model.dart
│   ├── log_model.dart
│   ├── expense_model.dart
│   └── ... (12 model dosyası)
├── providers/               # State Management (Business Logic Layer)
│   ├── auth_provider.dart
│   ├── pet_provider.dart    # En kritik provider (1012 satır)
│   ├── task_provider.dart
│   └── expense_provider.dart
├── services/                # External Service Integrations
│   ├── ai_service.dart      # Google AI entegrasyonu
│   ├── notification_service.dart
│   ├── recommendation_service.dart
│   └── reminder_service.dart
├── screens/                 # UI Layer (Presentation)
│   ├── auth/
│   ├── home/
│   ├── health/
│   ├── finance/
│   └── ... (6 ana ekran kategorisi)
└── widgets/                 # Reusable UI Components
```

#### State Management Pattern: **Provider Pattern (ChangeNotifier)**

Uygulama **Provider pattern** kullanıyor, ancak bu tam bir **Clean Architecture** değil. Yaklaşım daha çok **MVVM benzeri** ama **Repository Pattern** kullanılmıyor.

**Mevcut Yapı:**
- **Model**: Veri yapıları (`lib/models/`)
- **Provider**: Business logic + State management (`lib/providers/`)
- **View**: UI ekranları (`lib/screens/`)
- **Service**: External API entegrasyonları (`lib/services/`)

**Eksik Katmanlar (Clean Architecture açısından):**
- Repository katmanı yok (Supabase doğrudan Provider'dan çağrılıyor)
- Use case layer yok (Business logic Provider içinde)
- Data source abstraction yok

---

## 3. ANA İŞ AKIŞI (DATA FLOW)

### Örnek Senaryo: Yeni Bir Günlük Kayıt (Log) Oluşturma

Bir kullanıcı pet'inin fotoğrafını çeker ve AI analizi ile günlük kayıt oluşturur. İşte adım adım data flow:

#### **ADIM 1: UI - Kullanıcı Etkileşimi**
**Dosya:** `lib/screens/main_container.dart`
- **Fonksiyon:** `_showAddLogBottomSheet(BuildContext context, String petId)` (satır 66-123)
- **Akış:**
  1. Kullanıcı FAB (Floating Action Button) butonuna basar
  2. `ImagePicker().pickImage(source: ImageSource.gallery)` ile galeri açılır
  3. Fotoğraf seçilir → `XFile` objesi döner

#### **ADIM 2: Provider - İş Mantığı Başlangıcı**
**Dosya:** `lib/providers/pet_provider.dart`
- **Fonksiyon:** `prepareLogDraft(String petId, XFile imageFile)` (satır 568-635)
- **İşlemler:**
  1. **Loading state** aktif edilir (`_isLoadingLogs = true`, `notifyListeners()`)
  2. Pet bilgileri yüklenir: `_pets.firstWhere((p) => p.id == petId)`
  3. Pet yaşı hesaplanır: `DateTime.now().year - pet.birthDate.year`
  4. **Kronik durumlar** kontrol edilir: `await _ensureChronicConditionsLoaded(petId)`
  5. **Fotoğraf Supabase Storage'a yüklenir:**
     - Dosya adı oluşturulur: `'${DateTime.now().millisecondsSinceEpoch}_log.jpg'`
     - Path: `'daily-logs/$petId/$fileName'`
     - `SupabaseConfig.client.storage.from('pets_bucket').uploadBinary(path, bytes)`
     - Public URL alınır: `getPublicUrl(path)`
  6. **Önceki log özeti** oluşturulur: `_buildRecentStateSummary(petId)`
  7. **Pet profil notu** yüklenir: `await loadPetNote(petId)`
  8. **AI Servis çağrılır:** 
     - `AIService.analyzePetPhoto(imageFile, petName, petAge, recentState, profileNote)`
  9. AI yanıtı JSON'a parse edilir: `_extractJsonPayload(aiComment)`
  10. **PreparedLogData** objesi oluşturulur ve döner

#### **ADIM 3: Service - AI Analizi**
**Dosya:** `lib/services/ai_service.dart`
- **Fonksiyon:** `analyzePetPhoto(XFile imageFile, {...})` (satır 15-116)
- **İşlemler:**
  1. Fotoğraf bytes'a çevrilir: `await imageFile.readAsBytes()`
  2. MIME type belirlenir: `_getMimeType(imageFile.path)`
  3. **Prompt oluşturulur:**
     - Pet bilgileri (isim, yaş)
     - Son 3 kayıt özeti (context için)
     - Profil notu
     - 10 parametreli analiz talimatı
  4. **Google Gemini API çağrısı:**
     - `_visionModel.generateContent([Content.multi([TextPart, DataPart])])`
  5. JSON formatında yanıt döner

#### **ADIM 4: UI - Kullanıcı Onayı**
**Dosya:** `lib/screens/main_container.dart`
- **Fonksiyon:** `_pickVisibility(BuildContext context)` (satır 33-63)
- **İşlem:**
  1. Modal bottom sheet açılır
  2. Kullanıcı görünürlük seçer: 'members', 'followers', veya 'public'
  3. Seçilen değer döner

#### **ADIM 5: Provider - Veritabanına Kayıt**
**Dosya:** `lib/providers/pet_provider.dart`
- **Fonksiyon:** `submitLogDraft(PreparedLogData draft, {...})` (satır 637-691)
- **İşlemler:**
  1. **Kronik durumlar** birleştirilir: `_mergeConditions(persistedChronic, confirmedConditions)`
  2. **Insert payload** hazırlanır:
     ```dart
     {
       'pet_id': draft.petId,
       'photo_url': draft.photoUrl,
       'ai_comment': draft.aiComment,  // JSON string olarak
       'health_note': healthNote,
       'ai_conditions': draft.aiConditions.map((c) => c.toJson()),
       'confirmed_conditions': combinedChronic.map((c) => c.toJson()),
       'parameter_scores': draft.parameterScores,
       'parameter_notes': draft.parameterNotes,
       'visibility': visibility,
     }
     ```
  3. **Supabase'e INSERT:**
     - `SupabaseConfig.client.from('daily_logs').insert(insertPayload)`
  4. **Database trigger** çalışır (migrations.sql):
     - `calculate_log_score()` → `total_score` hesaplanır
     - `update_user_streak()` → Kullanıcı streak ve puanları güncellenir
  5. **Kronik durumlar kaydedilir** (eğer varsa):
     - `pet_conditions` tablosuna insert
  6. **UI güncellemesi:**
     - `await fetchLogs(draft.petId)` → Yeni log listeye eklenir
     - `await fetchChronicConditions(draft.petId)` → Kronik durumlar güncellenir
     - `notifyListeners()` → UI rebuild olur

#### **ADIM 6: UI - Yeni Veri Gösterimi**
**Dosya:** `lib/screens/home/home_screen.dart`
- **Provider'dan veri alınır:**
  - `context.watch<PetProvider>()`
  - `petProvider.getLogsForPet(selectedPet.id)`
- **LogModel** objeleri UI'da render edilir
- Kullanıcı yeni kaydı görür

### Data Flow Şeması

```
[UI: HomeScreen]
    ↓ FAB Click
[UI: MainContainer._showAddLogBottomSheet]
    ↓ ImagePicker
[User selects photo → XFile]
    ↓
[Provider: PetProvider.prepareLogDraft]
    ├─→ Supabase Storage: Upload image
    ├─→ Provider: _buildRecentStateSummary (context için)
    ├─→ Provider: loadPetNote
    └─→ Service: AIService.analyzePetPhoto
        └─→ Google Gemini API
            └─→ JSON Response
    ↓
[Provider: PreparedLogData oluşturulur]
    ↓
[UI: _pickVisibility modal]
    ↓ User selects visibility
[Provider: PetProvider.submitLogDraft]
    ├─→ Supabase: daily_logs.insert()
    │   └─→ Database Triggers:
    │       ├─→ calculate_log_score() → total_score
    │       └─→ update_user_streak() → streak & points
    ├─→ Supabase: pet_conditions.insert() (if any)
    └─→ Provider: fetchLogs() → UI update
    ↓
[UI: HomeScreen rebuilds → New log visible]
```

---

## 4. KRİTİK DOSYALAR

### 1. `lib/providers/pet_provider.dart` (1012+ satır)

**Neden Kritik:**
- Uygulamanın **en büyük ve en karmaşık** dosyası
- **Tüm core business logic** burada:
  - Pet CRUD işlemleri
  - Log oluşturma ve yönetimi
  - AI entegrasyonu orchestration
  - Kronik durum yönetimi
  - Aile üyesi yönetimi
  - Health parameter hesaplamaları
  - Trend analizleri
- **Single Responsibility Principle ihlali**: Çok fazla sorumluluğu var
- **State management** merkezi: Tüm pet/log/condition state'i burada
- **Supabase direkt entegrasyonu**: Repository pattern yok, doğrudan DB çağrıları

**İçindeki Önemli Metodlar:**
- `prepareLogDraft()` - Log hazırlama (AI analizi dahil)
- `submitLogDraft()` - Veritabanına kayıt
- `fetchLogs()` - Log listesi çekme
- `averageParameterScores()` - Sağlık skorları hesaplama
- `parameterTrendSeries()` - Trend analizleri
- `addPet()`, `updatePet()`, `deletePet()` - Pet yönetimi
- `addMember()`, `removeMember()` - Aile üyesi yönetimi

**Risk:** Bu dosya değiştirildiğinde tüm uygulama etkilenebilir.

---

### 2. `lib/services/ai_service.dart` (211 satır)

**Neden Kritik:**
- **Uygulamanın temel değer önerisi** burada gerçekleşiyor
- **Google Gemini API entegrasyonu** - External dependency
- **Kritik prompt engineering**: AI'ya gönderilen promptlar çok detaylı ve önemli
- **JSON parsing logic**: AI yanıtlarının parse edilmesi
- **Error handling**: AI servisi çökerse uygulamanın core özelliği kaybolur

**İçindeki Önemli Metodlar:**
- `analyzePetPhoto()` - Ana AI analiz fonksiyonu
- `detectPetIdentity()` - Pet türü tespiti
- `_extractJsonPayload()` - AI yanıtından JSON çıkarma

**Risk:** 
- API key hardcoded (güvenlik riski)
- Rate limiting yok
- Retry mechanism yok
- Cost control yok (API kullanım limiti)

---

### 3. `lib/core/supabase_config.dart` (16 satır)

**Neden Kritik:**
- **Tüm backend bağlantısı** buradan yönetiliyor
- **Singleton pattern**: `Supabase.instance.client`
- **Hardcoded credentials** (URL ve anon key) - Güvenlik riski
- **Tüm Provider'lar** bu dosyaya bağımlı

**İçeriği:**
```dart
static const String url = 'https://njxitwuvtrelvndbcgnk.supabase.co';
static const String anonKey = 'eyJhbGci...'; // Hardcoded!
```

**Risk:**
- Production/Development environment ayrımı yok
- Secrets management yok
- Key rotation zorluğu

---

## 5. MEVCUT DURUM VE EKSİKLER

### Kod Kalitesi Değerlendirmesi

#### ✅ İyi Yönler:
1. **Modüler Klasör Yapısı**: Models, Providers, Services, Screens ayrımı var
2. **Consistent Naming**: Türkçe yerelleştirme tutarlı
3. **UI Consistency**: Constants dosyasında design system tanımlı
4. **Error Logging**: `debugPrint` ve `_logSupabaseError` kullanılıyor
5. **State Management**: Provider pattern doğru kullanılmış
6. **Database Security**: RLS policies mevcut
7. **Type Safety**: Dart'ın type system kullanılıyor

#### ⚠️ Eksikler ve İyileştirme Alanları:

##### 1. **Unit Test Coverage: SIFIR**
- **Durum:** `test/widget_test.dart` sadece default Flutter test şablonu, gerçek test yok
- **Etki:** Kod değişikliklerinde regression riski yüksek
- **Öneri:** 
  - Provider testleri (pet_provider_test.dart)
  - Service testleri (ai_service_test.dart)
  - Model testleri
  - Widget testleri

##### 2. **Error Handling: YETERSİZ**
- **Mevcut:** Try-catch blokları var ama:
  - Error recovery mekanizması yok
  - User-friendly error messages yetersiz
  - Network error handling genel (`catch (e)`)
  - Retry logic yok (AI servisi için kritik)
- **Örnek:** `lib/services/ai_service.dart:110-114`
  ```dart
  catch (e) {
    print('--- AI Analiz Hatası ---');  // Sadece print, user'a generic mesaj
    return "AI asistanı şu an yanıt veremiyor.";
  }
  ```

##### 3. **Security Issues: CİDDİ**
- **Hardcoded API Keys:**
  - `lib/core/supabase_config.dart`: Supabase URL ve anon key
  - `lib/services/ai_service.dart`: Google Gemini API key
- **Risk:** API keys commit edilmiş, version control'da görünüyor
- **Öneri:** 
  - Environment variables kullanılmalı
  - `.env` dosyası `.gitignore`'a eklenmeli
  - Secrets management servisi (AWS Secrets Manager, Azure Key Vault)

##### 4. **Code Duplication: ORTA SEVİYE**
- **Tespit Edilen:**
  - Supabase client erişimi: `SupabaseConfig.client` her yerde tekrarlanıyor
  - Error logging: `_logSupabaseError` benzeri metodlar provider'larda tekrarlı
  - Photo upload logic: `pet_provider.dart` ve başka yerlerde benzer kod
- **Öneri:** 
  - Repository pattern eklenebilir
  - Shared utilities dosyası
  - Base provider class

##### 5. **Architecture: Repository Pattern Eksik**
- **Mevcut:** Provider'lar doğrudan Supabase'e bağlı
- **Sorun:** 
  - Test edilebilirlik düşük (mock zor)
  - Business logic ve data access karışık
  - Future'da farklı backend'e geçiş zor
- **Öneri:**
  ```
  lib/
  └── repositories/
      ├── pet_repository.dart
      ├── log_repository.dart
      └── expense_repository.dart
  ```

##### 6. **Loading States: TUTARSIZ**
- **Mevcut:** 
  - Bazı yerlerde loading indicator var
  - Bazı yerlerde yok
  - Error state gösterimi tutarsız
- **Örnek:** `pet_provider.dart`'ta `_isLoading` ve `_isLoadingLogs` ayrı state'ler

##### 7. **Null Safety: İYİ**
- Dart'ın null safety özellikleri kullanılıyor
- `?`, `!`, `??` operatörleri doğru kullanılmış

##### 8. **Documentation: YETERSİZ**
- Kod içi yorumlar minimal
- API documentation yok
- README.md boş (sadece Flutter default)
- Complex logic'lerde açıklama yok

##### 9. **Performance: ORTA**
- **Image Handling:** 
  - Image compression yok (büyük fotoğraflar yüklenebilir)
  - Cache mechanism yok
- **Network Calls:**
  - Pagination yok (tüm loglar bir seferde çekiliyor)
  - Debouncing yok (arama için)
- **State Management:**
  - `notifyListeners()` bazı yerlerde gereksiz çağrılıyor olabilir

##### 10. **TODO/FIXME Bulundu:**
- `lib/screens/finance/add_expense_screen.dart:58`: `// TODO: Upload to Supabase storage and get URL`
- Bu özellik eksik: Fiş fotoğrafları storage'a yüklenmiyor

---

### Production-Ready Değerlendirmesi

#### ❌ **PRODUCTION-READY DEĞİL** (MVP+ Aşamasında)

**Eksiklikler:**

1. **Security: CİDDİ**
   - ✅ RLS policies var
   - ❌ Hardcoded API keys
   - ❌ Environment configuration yok
   - ❌ Rate limiting yok
   - ❌ API key rotation mechanism yok

2. **Testing: CİDDİ**
   - ❌ Unit test yok
   - ❌ Integration test yok
   - ❌ Widget test yok
   - ❌ E2E test yok

3. **Monitoring & Logging: EKSİK**
   - ✅ `debugPrint` kullanılıyor (development için)
   - ❌ Production logging (Sentry, Firebase Crashlytics) yok
   - ❌ Analytics yok
   - ❌ Performance monitoring yok
   - ❌ Error tracking yok

4. **Error Handling: YETERSİZ**
   - ✅ Try-catch blokları var
   - ❌ Retry logic yok
   - ❌ Offline mode yok
   - ❌ Error recovery mechanism yok

5. **Documentation: YETERSİZ**
   - ❌ API documentation yok
   - ❌ User guide yok
   - ❌ Developer guide yok
   - ❌ Architecture decision records yok

6. **Code Quality: İYİ-ORTA**
   - ✅ Modüler yapı var
   - ⚠️ Bazı dosyalar çok büyük (pet_provider.dart 1000+ satır)
   - ⚠️ Code duplication var
   - ⚠️ Repository pattern eksik

7. **Performance: ORTA**
   - ⚠️ Image optimization yok
   - ⚠️ Pagination yok
   - ✅ State management iyi

8. **Deployment: BİLİNEMİYOR**
   - Code'da deployment configuration görünmüyor
   - CI/CD pipeline yok (görünmüyor)
   - Build scripts yok (görünmüyor)

---

## ÖZET VE ÖNERİLER

### Mevcut Durum
Uygulama **fonksiyonel bir MVP** seviyesinde. Core özellikler çalışıyor ama **production deployment için kritik eksiklikler** var.

### Acil Öncelikler (Production için):

1. **Security:**
   - API keys'i environment variables'a taşı
   - `.env` dosyasını `.gitignore`'a ekle
   - Secrets management implement et

2. **Testing:**
   - En az %60 code coverage hedefle
   - Critical path'ler için test yaz (log oluşturma, AI analizi)

3. **Error Handling:**
   - Retry logic ekle (özellikle AI servisi için)
   - User-friendly error messages
   - Offline mode desteği

4. **Monitoring:**
   - Sentry veya Firebase Crashlytics entegre et
   - Analytics ekle (Firebase Analytics, Mixpanel)

5. **Code Quality:**
   - `pet_provider.dart`'ı refactor et (Single Responsibility)
   - Repository pattern ekle
   - Code duplication'ları temizle

6. **Documentation:**
   - README.md'yi doldur
   - API documentation oluştur
   - Developer guide yaz

### Uzun Vadeli İyileştirmeler:

1. **Architecture:**
   - Clean Architecture'a geçiş planı
   - Dependency Injection (get_it) ekle

2. **Performance:**
   - Image compression
   - Pagination
   - Caching strategy

3. **Features:**
   - Offline-first architecture
   - Real-time sync (Supabase Realtime)
   - Push notifications (zaten service var ama entegre edilmeli)

---

**Rapor Sonu:** Bu analiz tamamen mevcut codebase'e dayalıdır. Hiçbir varsayım yapılmamış, sadece kodlardan görünen gerçekler raporlanmıştır.
