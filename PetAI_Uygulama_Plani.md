# PetAI - Teknik Uygulama Planı (Satış Odaklı Özellikler)

**Tarih:** 12 Ocak 2026  
**Yaklaşım:** Adım adım, öncelik bazlı implementasyon  
**Hedef:** Satış odaklı değer artırım raporundaki önerilerin teknik implementasyonu

---

## 📋 GENEL STRATEJİ

**Mobil App Odaklı 4 Phase Yaklaşımı:**
1. **Phase 1:** In-App Purchase Subscription Sistemi & Rate Limiting (App Store/Play Store)
2. **Phase 2:** Gamification Güçlendirme (Retention)
3. **Phase 3:** Basit Recommendation Sistemi (İçerik bazlı, partner gerektirmeyen)
4. **Phase 4:** Sosyal Özellikler (Growth & Retention)

**Not:** Veteriner entegrasyonu ve sigorta şirketleri partnership'leri daha sonraki aşama için ertelendi (B2B expansion phase).

**Her phase 2-3 hafta sürecek şekilde planlandı.**

---

## PHASE 1: SUBSCRIPTION SİSTEMİ & RATE LIMITING

### 🎯 Hedef
Temel monetization altyapısını kurmak. Kullanıcılar Free/Premium/Pro planlara sahip olabilmeli ve özelliklere göre kısıtlanmalı.

### 📦 Yapılacaklar

#### **1.1 Veritabanı Migration: Subscription & Usage Tracking**

**Dosya:** `supabase/subscription_migration.sql`

**Yeni Tablolar:**
- `subscription_plans` - Plan tanımları (free, premium, pro)
- `user_subscriptions` - Kullanıcı subscription durumu
- `usage_tracking` - AI analizi, log sayısı gibi kullanım takibi
- `subscription_history` - Subscription geçmişi (audit için)

**Özellikler:**
- Plan tipleri: 'free', 'premium', 'pro'
- Subscription durumu: 'active', 'canceled', 'expired', 'trial'
- Trial period desteği
- Usage limits per plan

**Migration içeriği:**
```sql
-- Subscription plans
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL, -- 'free', 'premium', 'pro'
  display_name TEXT NOT NULL,
  price_monthly DECIMAL(10,2),
  price_yearly DECIMAL(10,2),
  features JSONB NOT NULL, -- {'ai_analyses': 'unlimited', 'pets': 'unlimited'}
  trial_days INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User subscriptions
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  plan_id UUID REFERENCES subscription_plans(id),
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired', 'trial', 'grace_period')),
  started_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP,
  canceled_at TIMESTAMP,
  original_transaction_id TEXT, -- App Store/Play Store transaction ID
  revenuecat_customer_id TEXT, -- RevenueCat customer ID (eğer RevenueCat kullanılıyorsa)
  platform TEXT CHECK (platform IN ('ios', 'android')), -- Hangi platform'dan satın alındı
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Usage tracking (rate limiting için)
CREATE TABLE usage_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  feature_type TEXT NOT NULL, -- 'ai_analysis', 'log_creation', 'pdf_export'
  usage_date DATE NOT NULL,
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, feature_type, usage_date)
);

-- Insert default plans
-- Not: Fiyatlar App Store/Play Store'da belirlenecek, burada sadece plan yapısı
INSERT INTO subscription_plans (name, display_name, price_monthly, price_yearly, features) VALUES
('free', 'Ücretsiz', 0, 0, '{"ai_analyses_per_month": 3, "max_pets": 1, "pdf_exports": false, "advanced_analytics": false, "ad_free": false}'),
('premium', 'Premium', 0, 0, '{"ai_analyses_per_month": -1, "max_pets": -1, "pdf_exports": true, "advanced_analytics": true, "ad_free": true, "priority_ai_processing": true}'),
('pro', 'Pro', 0, 0, '{"ai_analyses_per_month": -1, "max_pets": -1, "pdf_exports": true, "advanced_analytics": true, "ad_free": true, "priority_ai_processing": true, "custom_themes": true, "advanced_export_formats": true}');

-- Not: Gerçek fiyatlar App Store Connect ve Google Play Console'da set edilecek
-- Önerilen fiyatlar:
-- Premium Monthly: ₺49/ay (Türkiye)
-- Premium Yearly: ₺490/yıl (₺40.8/ay - %17 indirim)
-- Pro Monthly: ₺99/ay (veteriner özellikleri olmadan, sadece advanced features)
-- Pro Yearly: ₺990/yıl (₺82.5/ay)
```

**RLS Policies:**
- Users can view their own subscription
- Admin can manage all subscriptions
- Usage tracking is user-specific

---

#### **1.2 Model Dosyaları**

**Dosya:** `lib/models/subscription_plan_model.dart`
- `SubscriptionPlan` modeli (id, name, displayName, priceMonthly, priceYearly, features)

**Dosya:** `lib/models/user_subscription_model.dart`
- `UserSubscription` modeli (id, userId, planId, status, startedAt, expiresAt, etc.)

**Dosya:** `lib/models/usage_tracking_model.dart`
- `UsageTracking` modeli (id, userId, featureType, usageDate, usageCount)

---

#### **1.3 Subscription Provider**

**Dosya:** `lib/providers/subscription_provider.dart`

**Metodlar:**
- `fetchUserSubscription()` - Kullanıcının aktif subscription'ını getir
- `checkFeatureAccess(String feature)` - Belirli özelliğe erişim kontrolü
- `checkUsageLimit(String featureType)` - Kullanım limiti kontrolü
- `incrementUsage(String featureType)` - Kullanım sayacını artır
- `getRemainingUsage(String featureType)` - Kalan kullanım sayısı
- `upgradeSubscription(String planId)` - Plan yükseltme
- `cancelSubscription()` - İptal işlemi

**Örnek kullanım:**
```dart
// AI analizi öncesi kontrol
final canAnalyze = subscriptionProvider.checkFeatureAccess('ai_analysis');
if (!canAnalyze) {
  // Premium'a yönlendir
}
```

---

#### **1.4 Rate Limiting Implementation**

**Dosya:** `lib/services/rate_limit_service.dart`

**Özellikler:**
- Aylık kullanım limitleri kontrolü
- Daily limits (opsiyonel)
- Usage tracking database'e kayıt
- Limit aşıldığında kullanıcıya bilgi

**PetProvider'da entegrasyon:**
- `prepareLogDraft()` metodunda rate limit kontrolü
- Limit varsa Premium upgrade prompt göster

---

#### **1.5 Subscription Ekranları**

**Dosya:** `lib/screens/subscription/subscription_screen.dart`
- Plan karşılaştırma tablosu
- Upgrade butonları
- Mevcut plan gösterimi

**Dosya:** `lib/screens/subscription/payment_screen.dart`
- Ödeme formu (Stripe entegrasyonu)
- Yıllık/aylık toggle
- Trial başlatma

**Widget:**
- `lib/screens/subscription/widgets/plan_card_widget.dart` - Plan kartı
- `lib/screens/subscription/widgets/feature_comparison_widget.dart` - Özellik karşılaştırma

---

#### **1.6 In-App Purchase Entegrasyonu (App Store/Play Store)**

**Yaklaşım:** App Store ve Google Play Store üzerinden subscription satışı

**Paket:** `in_app_purchase: ^3.1.11` (Flutter official) veya `purchases_flutter: ^6.x.x` (RevenueCat - önerilen)

**RevenueCat Neden Öneriliyor:**
- ✅ Cross-platform (iOS + Android) unified API
- ✅ Subscription yönetimi otomatik
- ✅ Receipt validation otomatik
- ✅ Webhook handling built-in
- ✅ Analytics dashboard
- ✅ A/B testing desteği

**Setup Adımları:**

**iOS (App Store Connect):**
1. App Store Connect'te subscription product'ları oluştur
   - `premium_monthly` (Aylık Premium)
   - `premium_yearly` (Yıllık Premium - %17 indirim)
   - `pro_monthly` (Aylık Pro) - İsteğe bağlı, şimdilik sadece Premium yeterli
   - `pro_yearly` (Yıllık Pro)
2. Product ID'leri al
3. App Store Connect'te RevenueCat'i bağla

**Android (Google Play Console):**
1. Google Play Console'da subscription product'ları oluştur
   - Aynı Product ID'ler (cross-platform için)
2. Product ID'leri al
3. Play Console'da RevenueCat'i bağla

**RevenueCat Setup:**
1. RevenueCat hesabı aç (free tier yeterli başlangıç için)
2. iOS ve Android app'leri bağla
3. Product ID'leri map'le
4. Webhook endpoint'i Supabase'e bağla

**Dosya:** `lib/services/purchase_service.dart`
- RevenueCat initialization
- Product fetching
- Purchase flow
- Subscription status check
- Restore purchases
- Webhook listener (backend'den subscription status güncellemesi için)

**Supabase Backend Integration:**
- RevenueCat webhook'u Supabase Edge Function'a gelecek
- Webhook'da subscription status güncellenecek (`user_subscriptions` tablosu)

---

#### **1.7 Feature Gating Implementation**

**Tüm ekranlarda:**
- Premium/Pro gereken özelliklere erişim kontrolü
- Upgrade prompts
- Feature badges (Premium/Pro rozetleri)

**Etkilenecek Ekranlar:**
- `health_screen.dart` - Advanced analytics → Premium
- `finance_screen.dart` - PDF export → Premium
- `pet_provider.dart` - Multiple pets → Premium
- `ai_service.dart` - Rate limiting → Free'de limit

---

### ⏱️ Tahmini Süre: 2-3 hafta

**Bağımlılıklar:**
- App Store Connect developer hesabı (Apple Developer Program - $99/yıl)
- Google Play Console developer hesabı (Google Play - $25 tek seferlik)
- RevenueCat hesabı (free tier başlangıç için yeterli)
- Supabase Edge Functions setup (RevenueCat webhook için)

---

## PHASE 2: GAMIFICATION GÜÇLENDİRME

### 🎯 Hedef
Kullanıcı retention'ını artırmak için gamification mekanizmalarını güçlendirmek.

### 📦 Yapılacaklar

#### **2.1 Achievement System**

**Migration:** `supabase/achievements_migration.sql`

**Tablo:** `achievements`
- Achievement tanımları (id, name, description, icon, points_reward)
- Achievement tipleri: 'first_log', 'streak_7', 'perfect_month', 'health_detective', etc.

**Tablo:** `user_achievements`
- Kullanıcıların kazandığı achievement'lar
- Unlocked_at timestamp

**Trigger:** Achievement otomatik kontrolü
- Her log kaydında achievement kontrolü
- Streak milestone'larında kontrol

**Model:** `lib/models/achievement_model.dart`

**Provider Metodu:** `pet_provider.dart`
- `checkAchievements(String petId)` - Achievement kontrolü
- `getUserAchievements()` - Kullanıcı achievement'ları

---

#### **2.2 Points Market (Puan Marketi)**

**Migration:** `supabase/points_shop_migration.sql`

**Tablo:** `points_shop_items`
- Ürünler (id, name, description, points_cost, item_type)
- Item tipleri: 'premium_trial', 'badge', 'customization', 'discount'

**Tablo:** `points_redemptions`
- Kullanıcı puan harcamaları

**Ekran:** `lib/screens/shop/points_shop_screen.dart`
- Puan marketi listesi
- Satın alma butonları
- Puan bakiyesi gösterimi

**Provider:** `lib/providers/shop_provider.dart`
- `fetchShopItems()`
- `redeemPoints(String itemId)`
- `getUserPointsBalance()`

---

#### **2.3 Streak Rewards & Milestones**

**Migration:** `supabase/streak_rewards_migration.sql`

**Tablo:** `streak_rewards`
- Milestone tanımları (7, 14, 30, 60, 100 gün)
- Reward tipleri: 'badge', 'premium_trial', 'points', 'discount'

**Trigger:** Streak milestone'a ulaşıldığında otomatik reward ver

**UI:** `lib/screens/home/widgets/streak_reward_widget.dart`
- Milestone celebration animasyonu
- Reward gösterimi

---

#### **2.4 Badge System**

**Tablo:** `user_badges`
- Kullanıcıların sahip olduğu rozetler
- Badge display order
- Unlocked date

**UI:** 
- Profile screen'de badge showcase
- Log card'larda badge gösterimi
- Achievement unlock animation

---

#### **2.5 Enhanced Leaderboard**

**Mevcut:** `leaderboard_screen.dart` var ama minimal

**İyileştirmeler:**
- Filtreleme (haftalık, aylık, global)
- Kategoriler (en çok log, en yüksek sağlık skoru, en uzun streak)
- User profile linkleri
- Badge gösterimi

**Yeni Tablo:** `leaderboard_rankings` (cache için)

---

### ⏱️ Tahmini Süre: 2 hafta

---

## PHASE 3: BASİT RECOMMENDATION SİSTEMİ (İçerik Bazlı)

### 🎯 Hedef
Kullanıcılara sağlık durumlarına göre genel öneriler sunmak. Partner gerektirmeyen, içerik bazlı sistem.

### 📦 Yapılacaklar

#### **3.1 Enhanced Recommendation Service (İçerik Bazlı)**

**Dosya:** `lib/services/recommendation_service.dart` (mevcut, genişletilecek)

**Yeni Metodlar:**
- `getHealthRecommendations(String petId)` - Düşük skor bazlı genel öneriler
- `getCareTips(String parameter, double score)` - Skor bazlı bakım ipuçları
- `getSeasonalRecommendations()` - Mevsimsel öneriler (zaten var, genişletilecek)

**Örnek Öneriler (Partner link yok, sadece bilgilendirme):**
- Kürk skoru düşükse: "Omega-3 takviyesi ve düzenli tarama önerilir"
- Stres seviyesi yüksekse: "Daha fazla oyun zamanı ve sakin ortam yaratmayı deneyin"
- Göz skoru düşükse: "Veteriner kontrolü önerilir"

**Not:** İleride partner agreement'ler yapıldığında affiliate link'ler eklenebilir, ama şimdilik sadece bilgilendirme.

---

#### **3.2 Recommendation Widget Enhancement**

**Dosya:** `lib/screens/finance/widgets/recommendations_widget.dart` (mevcut, genişletilecek)

**Yeni Özellikler:**
- Daha zengin öneri kartları
- Kategori bazlı öneriler (sağlık, finans, bakım)
- Action butonları (veteriner ara, hatırlatıcı kur, vs.)

---

#### **3.3 Acil Durum Tespiti ve Genel Uyarılar**

**Service:** `lib/services/health_alert_service.dart` (yeni)

**Özellikler:**
- Kritik sağlık skorları tespiti (örn: eye_clarity_score < 2)
- Push notification ile uyarı
- "Veteriner ara" butonu (genel araştırma linki, partner değil)

**Migration:** `supabase/health_alerts_migration.sql`
- `health_alerts` tablosu - Kritik durumların kaydı

---

### ⏱️ Tahmini Süre: 1-2 hafta

**Not:** Bu phase minimal effort ile yapılabilir, çünkü recommendation service zaten var ve sadece genişletilecek. Partner gerektirmiyor.

---

## PHASE 4: SOSYAL ÖZELLİKLER

### 🎯 Hedef
Viral growth ve user retention için sosyal özellikleri güçlendirmek.

### 📦 Yapılacaklar

#### **4.1 Comment System**

**Migration:** `supabase/comments_migration.sql`

**Tablo:** `log_comments`
- Log'lara yorum yapma
- Parent/child comment desteği (nested comments)
- Like/unlike yorumlar

**Model:** `lib/models/comment_model.dart`

**Provider:** `lib/providers/social_provider.dart` (yeni)
- `addComment(String logId, String comment)`
- `fetchComments(String logId)`
- `likeComment(String commentId)`
- `deleteComment(String commentId)`

**UI:** 
- `lib/screens/home/widgets/comment_section_widget.dart`
- Log detail screen'de comment section

---

#### **4.2 Follow System**

**Migration:** `supabase/follows_migration.sql`

**Tablo:** `user_follows`
- Kullanıcılar birbirini takip edebilir
- Follower/following sayıları

**Provider Metodları:**
- `followUser(String userId)`
- `unfollowUser(String userId)`
- `getFollowers(String userId)`
- `getFollowing(String userId)`

**UI:**
- User profile'da follow butonu
- Feed'de takip edilen kullanıcıların log'ları

---

#### **4.3 Pet Stories (24 Saatlik İçerik)**

**Migration:** `supabase/stories_migration.sql`

**Tablo:** `pet_stories`
- Photo/video stories
- 24 saatlik expiration
- View tracking

**Cron Job:** Expired stories'leri otomatik sil (Supabase Edge Function)

**UI:**
- `lib/screens/home/widgets/stories_widget.dart`
- Stories viewer screen
- Story creation screen

---

#### **4.4 Discovery Feed (For You Page)**

**Service:** `lib/services/discovery_service.dart`

**Algoritma:**
- Pet type, breed, location bazlı öneriler
- Popular content (beğeni/paylaşım bazlı)
- Trending pets

**UI:**
- `lib/screens/discovery/discovery_screen.dart`
- Infinite scroll feed
- Personalized recommendations

---

#### **4.5 Share Enhancements**

**Mevcut:** `share_plus` paketi var

**İyileştirmeler:**
- Custom share cards (pet fotoğrafı + health score)
- Deep linking (paylaşılan log'a direkt gitme)
- Social media optimization (Instagram, Facebook için optimized cards)

**Widget:** `lib/widgets/share_card_generator.dart`
- Pet health card generator
- Branded share images

---

### ⏱️ Tahmini Süre: 3 hafta

---

## PHASE 5: FUTURE - VETERİNER & B2B ENTEGRASYONU (ERTELENDİ)

### ⚠️ Not: Bu phase şu an için ertelendi

**Neden ertelendi:**
- Veteriner ve sigorta şirketleriyle partnership'ler henüz yok
- Önce B2C odaklı monetization (subscription) tamamlanmalı
- User base büyüdükten sonra B2B fırsatları değerlendirilebilir

**Ne zaman yapılabilir:**
- 10K+ aktif Premium kullanıcıdan sonra
- Veteriner partnership agreement'leri yapıldıktan sonra
- Market demand tespit edildikten sonra

**İçerecek özellikler (gelecekte):**
- Veteriner kayıt sistemi
- Telemedicine platform (video consultation)
- AI-powered vet matching
- Prescription management
- Veteriner dashboard (web app)
- B2B API'lar (sigorta şirketleri için data insights)

---

## TEKNİK DETAYLAR

### In-App Purchase (App Store/Play Store) Seçimi

**Öneri: RevenueCat + Flutter in_app_purchase**

**Neden RevenueCat:**
- ✅ Cross-platform unified API (iOS + Android tek kod)
- ✅ Subscription yönetimi otomatik (cancel, renew, etc.)
- ✅ Receipt validation otomatik (backend'de yapılıyor)
- ✅ Webhook handling built-in (Supabase'e subscription status güncellemesi)
- ✅ Analytics dashboard (conversion, churn, LTV)
- ✅ A/B testing desteği (fiyat testleri için)
- ✅ Free tier başlangıç için yeterli (10K MAU'ya kadar)

**Alternatif:** Native `in_app_purchase` paketi (daha manual, ama tam kontrol)

**Paket:** `purchases_flutter: ^6.29.0` (RevenueCat Flutter SDK)

**Setup Adımları:**

**1. RevenueCat Setup:**
```
1. RevenueCat hesabı aç (https://www.revenuecat.com)
2. Yeni proje oluştur
3. iOS ve Android app'leri ekle
```

**2. iOS (App Store Connect):**
```
1. App Store Connect'te subscription product'ları oluştur:
   - premium_monthly (Aylık Premium)
   - premium_yearly (Yıllık Premium)
   - pro_monthly (Aylık Pro - opsiyonel)
   - pro_yearly (Yıllık Pro - opsiyonel)

2. Fiyatları belirle:
   - Premium Monthly: ₺49/ay
   - Premium Yearly: ₺490/yıl (₺40.8/ay - %17 indirim)
   - Pro Monthly: ₺99/ay (opsiyonel)
   - Pro Yearly: ₺990/yıl (opsiyonel)

3. RevenueCat'te iOS app'i bağla
4. Product ID'leri map'le
```

**3. Android (Google Play Console):**
```
1. Google Play Console'da subscription product'ları oluştur
2. Aynı Product ID'leri kullan (cross-platform için)
3. Fiyatları set et (Türkiye için)
4. RevenueCat'te Android app'i bağla
5. Product ID'leri map'le
```

**4. Flutter Entegrasyonu:**
```dart
// pubspec.yaml
dependencies:
  purchases_flutter: ^6.29.0

// lib/services/purchase_service.dart
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static Future<void> initialize() async {
    await Purchases.setDebugLogsEnabled(true);
    
    // iOS
    if (Platform.isIOS) {
      await Purchases.configure(
        PurchasesConfiguration('REVENUECAT_IOS_API_KEY')
      );
    }
    
    // Android
    if (Platform.isAndroid) {
      await Purchases.configure(
        PurchasesConfiguration('REVENUECAT_ANDROID_API_KEY')
      );
    }
  }
  
  static Future<Offerings?> getOfferings() async {
    return await Purchases.getOfferings();
  }
  
  static Future<CustomerInfo> purchasePackage(Package package) async {
    return await Purchases.purchasePackage(package);
  }
  
  static Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }
}
```

**5. Webhook Setup (RevenueCat → Supabase):**
```
1. RevenueCat Dashboard → Integrations → Webhooks
2. Webhook URL: https://your-project.supabase.co/functions/v1/revenuecat-webhook
3. Supabase Edge Function oluştur (revenuecat-webhook)
4. Webhook'da subscription event'leri yakala
5. user_subscriptions tablosunu güncelle
```

**Test:**
- Sandbox accounts ile test (iOS: App Store Connect sandbox, Android: Play Console test)
- RevenueCat test mode

---

### Rate Limiting Stratejisi

**Free Plan:**
- 3 AI analizi/ay
- 1 pet profili
- Basic grafikler

**Premium Plan:**
- Sınırsız AI analizi
- Sınırsız pet
- Advanced analytics
- PDF export

**Pro Plan:**
- Premium özellikleri + 
- Custom themes
- Advanced export formats (JSON, Excel)
- Priority AI processing (daha hızlı analiz)
- (Veteriner consultation özellikleri Phase 5'te eklenecek)

**Implementation:**
- Database trigger ile usage tracking
- Monthly reset (cron job)
- Real-time limit check

---

### Achievement System Logic

**Achievement Types:**
1. **First Time:** İlk log, ilk pet, ilk streak
2. **Streak Milestones:** 7, 14, 30, 60, 100 gün
3. **Log Count:** 10, 50, 100, 500 log
4. **Health Scores:** Perfect score (5.0), Improvement streaks
5. **Social:** 100 beğeni, 50 yorum, 10 paylaşım
6. **Financial:** Bütçe hedefine ulaşma

**Trigger Logic:**
```sql
-- Example: 7-day streak achievement
CREATE TRIGGER check_streak_achievement
AFTER UPDATE ON profiles
FOR EACH ROW
WHEN (NEW.current_streak = 7 AND OLD.current_streak < 7)
EXECUTE FUNCTION grant_achievement('streak_7');
```

---

### Recommendation System Logic

**İçerik Bazlı Öneriler:**
- Health score threshold'larına göre öneriler
- Genel bakım ipuçları (partner link yok)
- Seasonal recommendations
- Expense-based suggestions

**Future (Partner Agreement'ler yapıldığında):**
- Affiliate link'ler eklenebilir
- Click tracking
- Commission calculation

---

## ÖNCELİK SIRASI

**İlk 30 Gün (Kritik):**
1. ✅ Phase 1: Subscription System (monetization için şart)
2. ✅ Phase 1: Rate Limiting (cost control için şart)

**İkinci 30 Gün (Retention):**
3. ✅ Phase 2: Achievement System
4. ✅ Phase 2: Points Shop

**Üçüncü 30 Gün (Revenue):**
5. ✅ Phase 3: Affiliate System
6. ✅ Phase 3: Product Recommendations

**Dördüncü 30 Gün (Growth):**
7. ✅ Phase 4: Comments & Follows
8. ✅ Phase 4: Stories

**Gelecek (User Base 10K+ olduktan sonra):**
9. ⏸️ Phase 5: Veteriner Entegrasyonu (B2B expansion)

---

## RİSKLER VE MITIGASYON

### Teknik Riskler

**1. Payment Gateway Integration Complexity**
- **Risk:** Stripe entegrasyonu zaman alabilir
- **Mitigation:** Test mode'da detaylı test, webhook handling için Supabase Edge Functions kullan

**2. Rate Limiting Performance**
- **Risk:** Her request'te database check yavaşlatabilir
- **Mitigation:** Usage tracking'i cache'le (Redis gerekirse), batch updates

**3. Affiliate Fraud**
- **Risk:** Fake clicks/conversions
- **Mitigation:** Conversion verification, minimum payout threshold, fraud detection

### İş Riski

**1. Low Conversion Rate**
- **Risk:** Premium conversion %8'den düşük olabilir
- **Mitigation:** A/B testing, pricing optimization, value communication

**2. Partner Agreements**
- **Risk:** Affiliate partner bulmak zor olabilir
- **Mitigation:** Pilot program ile başla, success story'ler ile scale et

---

## BAŞARI METRİKLERİ

**Phase 1 Success Criteria:**
- Subscription sistemi çalışıyor
- Rate limiting doğru çalışıyor
- İlk 100 Premium kullanıcı (%10 conversion)

**Phase 2 Success Criteria:**
- Achievement system çalışıyor
- Points shop aktif
- D7 retention %35+ (gamification sayesinde)

**Phase 3 Success Criteria:**
- Affiliate system çalışıyor
- İlk 10 affiliate partner
- Aylık affiliate revenue ₺10K+

**Phase 4 Success Criteria:**
- Comments & follows aktif
- Stories feature çalışıyor
- Social engagement %50+ artış

**Phase 3 Success Criteria:**
- Recommendation system çalışıyor
- Health alerts aktif
- User engagement %30+ artış

**Phase 4 Success Criteria:**
- Comments & follows aktif
- Stories feature çalışıyor
- Social engagement %50+ artış

---

Bu plan, satış raporundaki önerilerin teknik implementasyonunu adım adım detaylandırıyor. Her phase bağımsız olarak geliştirilebilir ama öncelik sırası önemli.
