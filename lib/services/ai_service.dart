import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/supabase_config.dart';

class AIService {
  static Future<String> _callGeminiEdgeFunction({
    required String instructions,
    required XFile imageFile,
    String model = 'gemini-2.5-pro',
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await SupabaseConfig.client.functions.invoke(
        'analyze-pet',
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: {
          'instructions': instructions,
          'imageBase64': base64Image,
          'model': model,
        },
      );

      if (response.status != 200) {
        throw Exception('Edge Function hatası: ${response.status}');
      }

      // Gemini standard response parsing
      final data = response.data as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('AI yanıt üretemedi.');
      }
      
      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('AI yanıt içeriği boş.');
      }

      return parts[0]['text'] as String;
    } catch (e) {
      debugPrint('Edge Function Call Error: $e');
      rethrow;
    }
  }

  static Future<String> analyzePetPhoto(
    XFile imageFile, {
    String? petName,
    int? petAge,
    String? recentState,
    String? profileNote,
    String languageCode = 'tr',
  }) async {
    try {
      final isEn = languageCode == 'en';
      
      final contextBlock = (recentState != null && recentState.trim().isNotEmpty)
          ? (isEn 
              ? "Last 3 records summary:\n$recentState\nDo not repeat this information, share new observations. Please avoid saying the same things."
              : "Son 3 kayıt özeti:\n$recentState\nBu bilgiyi tekrar etmeyip yeni gözlemlerini paylaş. Lütfen aynı şeylerden bahsetme")
          : (isEn 
              ? "Pet's previous status is unknown; make inferences directly from the photo."
              : "Petin önceki durumu bilinmiyor; doğrudan fotoğraftan çıkarım yap.");

      final profileBlock = (profileNote != null && profileNote.trim().isNotEmpty)
          ? (isEn ? "Profile note (from user): $profileNote" : "Profil notu (kullanıcıdan): $profileNote")
          : null;

      final instructions = isEn ? """
You are an experienced Professional Veterinary Observer conducting a detailed 10-axis biometric health scan from a photo.
${petName != null ? "Friend's name to analyze: $petName." : ""}
${petAge != null ? "Approximate age: $petAge." : ""}
$contextBlock
${profileBlock != null ? "$profileBlock\n" : ""}

Task (professional and measurable):
1) Review the last 3 records, avoid repeating sentences; only write changes or new findings.
2) If there are "Confirmed chronic conditions", do not re-diagnose; only give stable/improving/fluctuating status.
3) Mention ${petName ?? 'the pet'} in the Summary, care_tip, and pet_voice sentences naturally.
4) Generate detailed score (1=critical, 5=ideal) + short clinical note (short_note) for 10 biometric parameters:
   - Cover Fur/Skin/Face-Sensory/Physical Form/Vitality axes.
   - Provide both score and short_note (in English, max 100 characters) for each parameter.
5) Comments about eyes/nose/breath should be written in the correct area; do not mix them up.

Return response only as valid JSON (do not add other text):
{
  "mood_label": "<single word emotion>",
  "mood_score": <1-5>,
  "energy_score": <1-5>,
  "species": "<dog/cat/bird/etc in English>",
  "breed": "<guessed breed or 'mixed' in English>",
  "summary_tr": "<1 sentence summary for ${petName ?? 'the pet'} (max 140 characters) in English>",
  "care_tip_tr": "<1 sentence care suggestion for ${petName ?? 'the pet'} (max 140 characters) in English>",
  "confidence": <0-1>,
  "pet_voice_tr": "<3-4 sentences of heartfelt expression from ${petName ?? 'the pet'}'s mouth in English>",
  "fur_luster_score": <1-5>,
  "fur_luster_note": "<Fur luster comment in English>",
  "skin_hygiene_score": <1-5>,
  "skin_hygiene_note": "<Skin/hygiene comment in English>",
  "eye_clarity_score": <1-5>,
  "eye_clarity_note": "<Eye clarity/inflammation comment in English>",
  "nasal_discharge_score": <1-5>,
  "nasal_discharge_note": "<Nasal discharge/breath comment in English>",
  "ear_posture_score": <1-5>,
  "ear_posture_note": "<Ear posture/cleanliness comment in English>",
  "weight_index_score": <1-5>,
  "weight_index_note": "<Weight/body ratio comment in English>",
  "posture_alignment_score": <1-5>,
  "posture_alignment_note": "<Posture/spine comment in English>",
  "facial_relaxation_score": <1-5>,
  "facial_relaxation_note": "<Expression/relaxation comment in English>",
  "energy_vibe_score": <1-5>,
  "energy_vibe_note": "<Energy-vitality comment in English>",
  "stress_level_score": <1-5>,
  "stress_level_note": "<Stress trigger comment in English>",
  "notes": {
    "fur_luster": "<additional clinical detail or suggestion in English>",
    "skin_hygiene": "<...>",
    "eye_clarity": "<...>",
    "nasal_discharge": "<...>",
    "ear_posture": "<...>",
    "weight_index": "<...>",
    "posture_alignment": "<...>",
    "facial_relaxation": "<...>",
    "energy_vibe": "<...>",
    "stress_level": "<...>"
  }
}

Kurallar:
- Do not write anything other than JSON.
- All scores are between 1-5; can be integer or single decimal.
- Confidence is a decimal between 0-1 (e.g., 0.86).
- Notes should be clinical, short (max 120 characters), and related to ${petName ?? 'the pet'}.
- If there is uncertainty, state it in the relevant score note and reduce the confidence value.
- For chronic conditions, only use phrases like "under control/improving/fluctuating", do not raise new alarms.
""" : """
Sen deneyimli bir Profesyonel Veteriner Gözlemcisisin ve fotoğraftan 10 eksenli detaylı biyometrik sağlık taraması yapıyorsun.
${petName != null ? "Analiz edeceğin dostun adı: $petName." : ""}
${petAge != null ? "Yaklaşık yaşı: $petAge." : ""}
$contextBlock
${profileBlock != null ? "$profileBlock\n" : ""}

Görev (profesyonel ve ölçülebilir):
1) Son 3 kaydı incele, tekrar eden cümlelerden kaçın; sadece değişiklik veya yeni bulguları yaz.
2) "Onaylı kronik durumlar" varsa yeniden teşhis etme; sadece stabil/iyileşme/dalgalanma durumu ver.
3) Summary, care_tip ve pet_voice cümlelerinde mutlaka ${petName ?? 'dijital dostumuzu'} adını/zamirini geçirerek anlat.
4) 10 biyometrik parametre için detaylı skor (1=kritik, 5=ideal) + kısa klinik not (short_note) üret:
   - Kürk/Deri/Yüz-Duyu/Fiziksel Form/Vitalite eksenlerini kapsa.
   - Her parametre için hem score hem de short_note (Türkçe, max 100 karakter) ver.
5) Göz/burun/nefes ile ilgili yorumlar doğru alana yazılmalı; karışıklık yapma.

Yanıtı sadece geçerli JSON olarak döndür (başka metin ekleme):
{
  "mood_label": "<tek kelime duygu>",
  "mood_score": <1-5>,
  "energy_score": <1-5>,
  "species": "<kedi/köpek/kuş/vb>",
  "breed": "<tahmin edilen ırk veya 'melez'>",
  "summary_tr": "<${petName ?? 'Bu can dostumuz'} için 1 cümle özet (max 140 karakter)>",
  "care_tip_tr": "<${petName ?? 'Bu sevimli dostumuz'} için 1 cümle bakım önerisi (max 140 karakter)>",
  "confidence": <0-1>,
  "pet_voice_tr": "<${petName ?? 'Onun'} ağzından 3-4 cümle içten ifade>",
  "fur_luster_score": <1-5>,
  "fur_luster_note": "<Kürk parlaklığı yorumu>",
  "skin_hygiene_score": <1-5>,
  "skin_hygiene_note": "<Deri/temizlik yorumu>",
  "eye_clarity_score": <1-5>,
  "eye_clarity_note": "<Göz parlaklığı/iltihap yorumu>",
  "nasal_discharge_score": <1-5>,
  "nasal_discharge_note": "<Burun akıntısı/nefes yorumu>",
  "ear_posture_score": <1-5>,
  "ear_posture_note": "<Kulak duruşu/temizliği yorumu>",
  "weight_index_score": <1-5>,
  "weight_index_note": "<Kilo/vücut oranı yorumu>",
  "posture_alignment_score": <1-5>,
  "posture_alignment_note": "<Duruş/omurga yorumu>",
  "facial_relaxation_score": <1-5>,
  "facial_relaxation_note": "<Mimik/gevşeme yorumu>",
  "energy_vibe_score": <1-5>,
  "energy_vibe_note": "<Enerji-vitalite yorumu>",
  "stress_level_score": <1-5>,
  "stress_level_note": "<Stres tetikleyicisi yorumu>",
  "notes": {
    "fur_luster": "<ek klinik detay veya öneri>",
    "skin_hygiene": "<...>",
    "eye_clarity": "<...>",
    "nasal_discharge": "<...>",
    "ear_posture": "<...>",
    "weight_index": "<...>",
    "posture_alignment": "<...>",
    "facial_relaxation": "<...>",
    "energy_vibe": "<...>",
    "stress_level": "<...>"
  }
}

Kurallar:
- JSON dışında hiçbir şey yazma.
- Tüm skorlar 1-5 arasında; tam sayı veya tek ondalık olabilir.
- confidence 0-1 arası ondalık (örn. 0.86).
- Notlar klinik, kısa (max 120 karakter) ve $petName adıyla ilişkilendir.
- Belirsizlik varsa ilgili skor notunda belirt ve confidence değerini düşür.
- Kronik başlıklarda sadece “kontrol altında/iyileşiyor/dalgalı” gibi ifadeler kullan, yeni alarm verme.
""";

      final responseText = await _callGeminiEdgeFunction(
        instructions: instructions,
        imageFile: imageFile,
        model: 'gemini-2.5-pro',
      );
      return responseText;
    } catch (e) {
      // Yapılandırma ve analiz hatalarını üst katmana iletip
      // kullanıcıya doğru geri bildirim verilmesini sağlarız.
      if (e is StateError) rethrow;
      debugPrint('--- AI Analiz Hatası ---');
      debugPrint(e.toString());
      throw Exception('AI analizi başarısız oldu: $e');
    }
  }

  static Future<PetIdentityResult?> detectPetIdentity(XFile imageFile) async {
    try {
      const instructions = '''
Fotoğraftaki evcil hayvanın türünü, cinsini, tahmini kilosunu ve cinsiyetini tespit et.
Yanıtı sadece aşağıdaki JSON formatında ver:
{
  "type_label": "<Köpek|Kedi|Kuş|Hamster|Diğer>",
  "breed_label": "<Cins veya açıklama>",
  "estimated_weight_kg": <tahmini kilo kg cinsinden, ondalık sayı>,
  "estimated_gender": "<Erkek|Dişi>",
  "confidence": <0-1 arası ondalık>
}
Kurallar:
- type_label sadece listelenen Türkçe değerlerden biri olmalı. Emin değilsen "Diğer" seç.
- estimated_weight_kg: Hayvanın görünümüne, ırkına ve boyutuna göre kg cinsinden tahmini ağırlık. Tam sayı veya tek ondalık olabilir (örn: 5.5).
- estimated_gender: Fiziksel özelliklerden tahmin et. Emin değilsen yüz yapısı, vücut büyüklüğü ve genel görünümden çıkarım yap. Erkek veya Dişi olarak belirt.
- JSON dışında açıklama ekleme.
''';

      final raw = await _callGeminiEdgeFunction(
        instructions: instructions,
        imageFile: imageFile,
        model: 'gemini-2.5-pro',
      );
      final payload = _extractJsonPayload(raw);
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      return PetIdentityResult(
        typeLabel: decoded['type_label'] as String?,
        breedLabel: decoded['breed_label'] as String?,
        estimatedWeightKg: (decoded['estimated_weight_kg'] as num?)?.toDouble(),
        estimatedGender: decoded['estimated_gender'] as String?,
        confidence: (decoded['confidence'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('--- AI Kimlik Tespiti Hatası ---');
      debugPrint(e.toString());
      return null;
    }
  }


  static String _extractJsonPayload(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final fenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final fenceMatch = fenceRegex.firstMatch(input);
    if (fenceMatch != null) {
      final fenced = fenceMatch.group(1)?.trim();
      if (fenced != null && fenced.isNotEmpty) {
        return fenced;
      }
    }

    final start = input.indexOf('{');
    final end = input.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return input.substring(start, end + 1).trim();
    }
    return trimmed;
  }

  /// Pet tipi ve cinsine göre AI ile akıllı görev önerileri üret
  /// Bu metod pet tipi/cinsine göre önerilen görevleri döndürür
  static Future<List<AISuggestedTask>> suggestTasksForPetType({
    required String petName,
    required String petType,
    String? breed,
    int? ageInMonths,
  }) async {
    try {
      final suggestions = <AISuggestedTask>[];
      final normalizedType = petType.toLowerCase();

      // Köpekler için öneriler
      if (normalizedType.contains('köpek') || normalizedType.contains('dog')) {
        suggestions.addAll(_getDogTaskSuggestions(petName, breed, ageInMonths));
      }
      // Kediler için öneriler
      else if (normalizedType.contains('kedi') ||
          normalizedType.contains('cat')) {
        suggestions.addAll(_getCatTaskSuggestions(petName, breed, ageInMonths));
      }
      // Kuşlar için öneriler
      else if (normalizedType.contains('kuş') ||
          normalizedType.contains('bird')) {
        suggestions
            .addAll(_getBirdTaskSuggestions(petName, breed, ageInMonths));
      }
      // Tavşanlar için öneriler
      else if (normalizedType.contains('tavşan') ||
          normalizedType.contains('rabbit')) {
        suggestions
            .addAll(_getRabbitTaskSuggestions(petName, breed, ageInMonths));
      }
      // Hamsterlar için öneriler
      else if (normalizedType.contains('hamster')) {
        suggestions
            .addAll(_getHamsterTaskSuggestions(petName, breed, ageInMonths));
      }

      return suggestions;
    } catch (e) {
      debugPrint('AI pet tipi görev önerisi hatası: $e');
      return [];
    }
  }

  /// Köpek görev önerileri
  static List<AISuggestedTask> _getDogTaskSuggestions(
      String petName, String? breed, int? ageInMonths) {
    final suggestions = <AISuggestedTask>[];

    // Yavru köpekler için öneriler
    if (ageInMonths != null && ageInMonths < 12) {
      suggestions.add(AISuggestedTask(
        name: 'Sosyalleşme Eğitimi',
        description:
            '$petName için erken dönem sosyalleşme çok önemli. Diğer köpekler ve insanlarla tanıştır.',
        category: 'training',
        priority: 'high',
        reason: 'Yavru köpeklerde sosyalleşme kritik öneme sahiptir',
      ));

      suggestions.add(AISuggestedTask(
        name: 'Temel Komut Eğitimi',
        description: '$petName için temel komutlar (otur, kalk, bekle) öğret.',
        category: 'training',
        priority: 'high',
        reason: 'Erken eğitim kalıcı davranışlar oluşturur',
      ));
    }

    // Tüm köpekler için genel öneriler
    suggestions.add(AISuggestedTask(
      name: 'Günlük Egzersiz',
      description: '$petName için günlük yürüyüş ve aktivite çok önemli.',
      category: 'health',
      priority: 'high',
      reason: 'Köpekler için düzenli egzersiz sağlık için kritiktir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Zihinsel Uyarım Oyunları',
      description: '$petName için zeka oyunları ve bulmaca oyuncakları kullan.',
      category: 'social',
      priority: 'medium',
      reason: 'Zihinsel uyarım köpeklerin mutluluğu için önemlidir',
    ));

    // Enerji seviyesi yüksek ırklar için
    if (breed != null) {
      final highEnergyBreeds = [
        'border collie',
        'australian shepherd',
        'belçika çoban',
        'sibirya kurdu',
        'husky'
      ];
      if (highEnergyBreeds.any((b) => breed.toLowerCase().contains(b))) {
        suggestions.add(AISuggestedTask(
          name: 'Yoğun Egzersiz ve Aktivite',
          description:
              '$petName yüksek enerjili bir ırk, daha fazla aktivite gerekebilir.',
          category: 'health',
          priority: 'high',
          reason: 'Yüksek enerjili ırklar daha fazla aktiviteye ihtiyaç duyar',
        ));
      }
    }

    return suggestions;
  }

  /// Kedi görev önerileri
  static List<AISuggestedTask> _getCatTaskSuggestions(
      String petName, String? breed, int? ageInMonths) {
    final suggestions = <AISuggestedTask>[];

    suggestions.add(AISuggestedTask(
      name: 'Günlük Oyun Zamanı',
      description:
          '$petName için günlük interaktif oyunlar (ip, lazer, oyuncak fare) düzenle.',
      category: 'social',
      priority: 'high',
      reason: 'Kediler için oyun fiziksel ve zihinsel sağlık için önemlidir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Kum Kabı Temizliği',
      description:
          '$petName için kum kabını günlük temizle ve haftalık değiştir.',
      category: 'hygiene',
      priority: 'high',
      reason: 'Temiz kum kabı kedilerin sağlığı ve mutluluğu için kritiktir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Tırmalama Yüzeyleri',
      description: '$petName için tırmalama tahtası veya direği sağla.',
      category: 'care',
      priority: 'medium',
      reason:
          'Tırmalama kedilerin doğal davranışıdır ve tırnak sağlığı için önemlidir',
    ));

    // Yavru kediler için
    if (ageInMonths != null && ageInMonths < 12) {
      suggestions.add(AISuggestedTask(
        name: 'Sosyalleşme ve Alıştırma',
        description:
            '$petName için erken dönemde farklı seslere ve dokunmaya alıştır.',
        category: 'training',
        priority: 'high',
        reason: 'Yavru kedilerde erken sosyalleşme önemlidir',
      ));
    }

    return suggestions;
  }

  /// Kuş görev önerileri
  static List<AISuggestedTask> _getBirdTaskSuggestions(
      String petName, String? breed, int? ageInMonths) {
    final suggestions = <AISuggestedTask>[];

    suggestions.add(AISuggestedTask(
      name: 'Kafes Temizliği',
      description: '$petName için kafesi düzenli temizle ve havalandır.',
      category: 'hygiene',
      priority: 'high',
      reason: 'Temiz kafes kuşların sağlığı için kritiktir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Sosyal Etkileşim',
      description: '$petName ile günlük konuşma ve etkileşim zamanı ayır.',
      category: 'social',
      priority: 'high',
      reason: 'Kuşlar sosyal hayvanlardır ve etkileşime ihtiyaç duyar',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Oyuncak ve Uyarım',
      description:
          '$petName için kafes içinde oyuncaklar ve zihinsel uyarım sağla.',
      category: 'care',
      priority: 'medium',
      reason: 'Zihinsel uyarım kuşların mutluluğu için önemlidir',
    ));

    return suggestions;
  }

  /// Tavşan görev önerileri
  static List<AISuggestedTask> _getRabbitTaskSuggestions(
      String petName, String? breed, int? ageInMonths) {
    final suggestions = <AISuggestedTask>[];

    suggestions.add(AISuggestedTask(
      name: 'Kafes ve Yaşam Alanı Temizliği',
      description: '$petName için yaşam alanını düzenli temizle.',
      category: 'hygiene',
      priority: 'high',
      reason: 'Temiz yaşam alanı tavşanların sağlığı için önemlidir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Günlük Oyun ve Egzersiz',
      description:
          '$petName için güvenli bir alanda günlük egzersiz ve oyun zamanı.',
      category: 'health',
      priority: 'high',
      reason: 'Tavşanlar için düzenli hareket sağlık için kritiktir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Taze Ot ve Yeşillik',
      description: '$petName için günlük taze ot, sebze ve yeşillik sağla.',
      category: 'care',
      priority: 'high',
      reason: 'Tavşanlar için taze gıdalar beslenme sağlığı için önemlidir',
    ));

    return suggestions;
  }

  /// Hamster görev önerileri
  static List<AISuggestedTask> _getHamsterTaskSuggestions(
      String petName, String? breed, int? ageInMonths) {
    final suggestions = <AISuggestedTask>[];

    suggestions.add(AISuggestedTask(
      name: 'Kafes Temizliği',
      description: '$petName için kafesi düzenli temizle ve altlığı değiştir.',
      category: 'hygiene',
      priority: 'high',
      reason: 'Temiz kafes hamsterların sağlığı için kritiktir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Oyuncak ve Eğlence',
      description: '$petName için egzersiz tekerleği ve oyuncaklar sağla.',
      category: 'care',
      priority: 'medium',
      reason: 'Hamsterlar için aktivite ve oyun önemlidir',
    ));

    suggestions.add(AISuggestedTask(
      name: 'Beslenme Kontrolü',
      description: '$petName için dengeli beslenme ve taze su sağla.',
      category: 'care',
      priority: 'high',
      reason:
          'Hamsterlar için düzenli ve dengeli beslenme sağlık için önemlidir',
    ));

    return suggestions;
  }

  /// AI analizinden görev önerileri üret
  /// Log analizi sonrası, tespit edilen sorunlara göre görev önerileri döner
  static Future<List<AISuggestedTask>> suggestTasksFromAnalysis({
    required Map<String, dynamic> aiAnalysisJson,
    required String petName,
    required String petType,
  }) async {
    try {
      final suggestions = <AISuggestedTask>[];

      // Göz sorunları kontrolü
      final eyeScore = aiAnalysisJson['eye_clarity_score'] as num?;
      final eyeNote = aiAnalysisJson['eye_clarity_note'] as String?;
      if (eyeScore != null &&
          eyeScore < 3 &&
          ((eyeNote?.toLowerCase().contains('iltihap') ?? false) ||
              (eyeNote?.toLowerCase().contains('kızarık') ?? false) ||
              (eyeNote?.toLowerCase().contains('akıntı') ?? false))) {
        suggestions.add(AISuggestedTask(
          name: 'Veteriner Kontrolü - Göz',
          description:
              '$petName için göz kontrolü gerekli. AI analizi göz sorunu tespit etti.',
          category: 'health',
          priority: 'high',
          reason: eyeNote ?? 'Göz sağlığında sorun tespit edildi',
        ));
      }

      // Burun/Solunum sorunları
      final nasalScore = aiAnalysisJson['nasal_discharge_score'] as num?;
      final nasalNote = aiAnalysisJson['nasal_discharge_note'] as String?;
      if (nasalScore != null &&
          nasalScore < 3 &&
          ((nasalNote?.toLowerCase().contains('akıntı') ?? false) ||
              (nasalNote?.toLowerCase().contains('nefes') ?? false))) {
        suggestions.add(AISuggestedTask(
          name: 'Solunum Kontrolü',
          description: '$petName için solunum sistemi kontrolü öneriliyor.',
          category: 'health',
          priority: 'high',
          reason: nasalNote ?? 'Solunum sorunu tespit edildi',
        ));
      }

      // Kilo sorunları
      final weightScore = aiAnalysisJson['weight_index_score'] as num?;
      final weightNote = aiAnalysisJson['weight_index_note'] as String?;
      if (weightScore != null) {
        if (weightScore < 2.5) {
          suggestions.add(AISuggestedTask(
            name: 'Kilo Takibi',
            description:
                '$petName için kilo takibi başlatılmalı. AI analizi kilo sorunu tespit etti.',
            category: 'health',
            priority: 'medium',
            reason: weightNote ?? 'Kilo endeksi düşük',
          ));
        } else if (weightScore > 4.5) {
          suggestions.add(AISuggestedTask(
            name: 'Diyet Kontrolü',
            description: '$petName için diyet planı gözden geçirilmeli.',
            category: 'health',
            priority: 'medium',
            reason: weightNote ?? 'Kilo endeksi yüksek',
          ));
        }
      }

      // Stres seviyesi yüksek
      final stressScore = aiAnalysisJson['stress_level_score'] as num?;
      final stressNote = aiAnalysisJson['stress_level_note'] as String?;
      if (stressScore != null && stressScore < 3) {
        suggestions.add(AISuggestedTask(
          name: 'Dinlenme ve Rahatlama',
          description:
              '$petName için stres seviyesi yüksek. Dinlenme süresi artırılmalı.',
          category: 'care',
          priority: 'medium',
          reason: stressNote ?? 'Stres seviyesi yüksek',
        ));
      }

      // Enerji düşük
      final energyScore = aiAnalysisJson['energy_score'] as num?;
      if (energyScore != null && energyScore < 2.5) {
        suggestions.add(AISuggestedTask(
          name: 'Enerji Takibi',
          description:
              '$petName için enerji seviyesi düşük. Aktivite ve beslenme gözden geçirilmeli.',
          category: 'health',
          priority: 'medium',
          reason: 'Enerji seviyesi düşük',
        ));
      }

      // Deri/Hijyen sorunları
      final skinScore = aiAnalysisJson['skin_hygiene_score'] as num?;
      final skinNote = aiAnalysisJson['skin_hygiene_note'] as String?;
      if (skinScore != null && skinScore < 3) {
        suggestions.add(AISuggestedTask(
          name: 'Deri Kontrolü',
          description: '$petName için deri ve hijyen kontrolü öneriliyor.',
          category: 'hygiene',
          priority: 'medium',
          reason: skinNote ?? 'Deri sağlığında sorun',
        ));
      }

      // Kulak sorunları
      final earScore = aiAnalysisJson['ear_posture_score'] as num?;
      final earNote = aiAnalysisJson['ear_posture_note'] as String?;
      if (earScore != null &&
          earScore < 3 &&
          ((earNote?.toLowerCase().contains('iltihap') ?? false) ||
              (earNote?.toLowerCase().contains('akıntı') ?? false))) {
        suggestions.add(AISuggestedTask(
          name: 'Kulak Kontrolü',
          description: '$petName için kulak kontrolü öneriliyor.',
          category: 'hygiene',
          priority: 'medium',
          reason: earNote ?? 'Kulak sağlığında sorun',
        ));
      }

      return suggestions;
    } catch (e) {
      debugPrint('AI görev önerisi hatası: $e');
      return [];
    }
  }
}

class AISuggestedTask {
  final String name;
  final String description;
  final String category; // 'health', 'care', 'hygiene'
  final String priority; // 'high', 'medium', 'low'
  final String reason; // AI'nin tespit ettiği neden

  AISuggestedTask({
    required this.name,
    required this.description,
    required this.category,
    required this.priority,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'priority': priority,
      'reason': reason,
    };
  }
}

class PetIdentityResult {
  final String? typeLabel;
  final String? breedLabel;
  final double? estimatedWeightKg;
  final String? estimatedGender;
  final double? confidence;

  const PetIdentityResult({
    this.typeLabel,
    this.breedLabel,
    this.estimatedWeightKg,
    this.estimatedGender,
    this.confidence,
  });

  bool get hasAnyData =>
      (typeLabel != null && typeLabel!.trim().isNotEmpty) ||
      (breedLabel != null && breedLabel!.trim().isNotEmpty);

  @override
  String toString() =>
      'type: ${typeLabel ?? "-"}, breed: ${breedLabel ?? "-"}, weight: ${estimatedWeightKg?.toStringAsFixed(1) ?? "-"}kg, gender: ${estimatedGender ?? "-"}, confidence: ${confidence?.toStringAsFixed(2) ?? "-"}';
}
