import '../models/pet_model.dart';

/// Aşı takvimi bilgisi
class VaccineSchedule {
  final String name;
  final String description;
  final int recommendedAgeInDays; // Doğumdan itibaren kaç gün sonra
  final String? additionalInfo;
  final bool isRequired; // Zorunlu mu (true) yoksa önerilen mi (false)

  const VaccineSchedule({
    required this.name,
    required this.description,
    required this.recommendedAgeInDays,
    this.additionalInfo,
    this.isRequired = true,
  });
}

/// Pet yaşına göre aşı takvimi servisi
class VaccineScheduleService {
  /// Pet tipi ve yaşına göre önerilen aşıları döndürür
  static List<VaccineSchedule> getRecommendedVaccines(PetModel pet) {
    final normalizedType = pet.type.toLowerCase();
    final ageInDays = pet.ageInDays;
    final ageInMonths = pet.ageInMonths;

    if (normalizedType.contains('köpek') || normalizedType.contains('dog')) {
      return _getDogVaccines(ageInDays, ageInMonths);
    } else if (normalizedType.contains('kedi') || normalizedType.contains('cat')) {
      return _getCatVaccines(ageInDays, ageInMonths);
    } else if (normalizedType.contains('kuş') || normalizedType.contains('bird')) {
      return _getBirdVaccines(ageInDays, ageInMonths);
    } else if (normalizedType.contains('tavşan') || normalizedType.contains('rabbit')) {
      return _getRabbitVaccines(ageInDays, ageInMonths);
    } else if (normalizedType.contains('hamster')) {
      return _getHamsterVaccines(ageInDays, ageInMonths);
    }

    return [];
  }

  /// Köpek aşı takvimi
  static List<VaccineSchedule> _getDogVaccines(int ageInDays, int ageInMonths) {
    final vaccines = <VaccineSchedule>[];

    // Yavru köpek aşıları (6-16 hafta arası)
    if (ageInDays >= 42 && ageInDays < 112) {
      // 6-8 hafta: İlk karma aşı
      if (ageInDays >= 42 && ageInDays < 70) {
        vaccines.add(const VaccineSchedule(
          name: 'İlk Karma Aşı (DHPPi)',
          description: 'Distemper, Hepatit, Parvovirüs, Parainfluenza aşısı',
          recommendedAgeInDays: 42,
          isRequired: true,
        ));
      }

      // 10-12 hafta: İkinci karma aşı
      if (ageInDays >= 70 && ageInDays < 84) {
        vaccines.add(const VaccineSchedule(
          name: 'İkinci Karma Aşı (DHPPi)',
          description: 'Karma aşının tekrarı - bağışıklığı güçlendirme',
          recommendedAgeInDays: 70,
          isRequired: true,
        ));
      }

      // 12-16 hafta: Üçüncü karma aşı + Kuduz
      if (ageInDays >= 84 && ageInDays < 112) {
        vaccines.add(const VaccineSchedule(
          name: 'Üçüncü Karma Aşı (DHPPi)',
          description: 'Karma aşının son tekrarı',
          recommendedAgeInDays: 84,
          isRequired: true,
        ));
        vaccines.add(const VaccineSchedule(
          name: 'Kuduz Aşısı',
          description: 'İlk kuduz aşısı',
          recommendedAgeInDays: 84,
          isRequired: true,
        ));
      }
    }

    // 1 yaş: Yıllık aşılar
    if (ageInMonths >= 12 && ageInMonths < 14) {
      vaccines.add(const VaccineSchedule(
        name: 'Yıllık Karma Aşı (DHPPi)',
        description: 'Yıllık karma aşı tekrarı',
        recommendedAgeInDays: 365,
        isRequired: true,
      ));
      vaccines.add(const VaccineSchedule(
        name: 'Yıllık Kuduz Aşısı',
        description: 'Yıllık kuduz aşısı tekrarı',
        recommendedAgeInDays: 365,
        isRequired: true,
      ));
    }

    // Yetişkin köpek (2+ yaş): Her yıl yıllık aşılar
    if (ageInMonths >= 24) {
      // Her 365 günde bir tekrarlanmalı (yaklaşık kontrol)
      final yearsSinceLast = (ageInDays % 365);
      if (yearsSinceLast < 30 || yearsSinceLast > 335) {
        vaccines.add(const VaccineSchedule(
          name: 'Yıllık Karma Aşı (DHPPi)',
          description: 'Yıllık karma aşı tekrarı',
          recommendedAgeInDays: 365,
          isRequired: true,
        ));
        vaccines.add(const VaccineSchedule(
          name: 'Yıllık Kuduz Aşısı',
          description: 'Yıllık kuduz aşısı tekrarı',
          recommendedAgeInDays: 365,
          isRequired: true,
        ));
      }
    }

    // İsteğe bağlı aşılar (her zaman önerilebilir)
    vaccines.add(const VaccineSchedule(
      name: 'Kennel Cough (Bordetella)',
      description: 'Özellikle köpek parkı/sosyal ortamlarda önemli',
      recommendedAgeInDays: 70,
      isRequired: false,
      additionalInfo: 'Yılda 1-2 kez tekrarlanabilir',
    ));

    vaccines.add(const VaccineSchedule(
      name: 'Lyme Aşısı',
      description: 'Kene bölgelerinde yaşayan köpekler için önerilir',
      recommendedAgeInDays: 70,
      isRequired: false,
      additionalInfo: 'Veteriner hekiminize danışın',
    ));

    return vaccines;
  }

  /// Kedi aşı takvimi
  static List<VaccineSchedule> _getCatVaccines(int ageInDays, int ageInMonths) {
    final vaccines = <VaccineSchedule>[];

    // Yavru kedi aşıları (6-16 hafta arası)
    if (ageInDays >= 42 && ageInDays < 112) {
      // 6-8 hafta: İlk karma aşı (FVRCP)
      if (ageInDays >= 42 && ageInDays < 70) {
        vaccines.add(const VaccineSchedule(
          name: 'İlk Karma Aşı (FVRCP)',
          description: 'Feline Viral Rhinotracheitis, Calicivirus, Panleukopenia',
          recommendedAgeInDays: 42,
          isRequired: true,
        ));
      }

      // 10-12 hafta: İkinci karma aşı
      if (ageInDays >= 70 && ageInDays < 84) {
        vaccines.add(const VaccineSchedule(
          name: 'İkinci Karma Aşı (FVRCP)',
          description: 'Karma aşının tekrarı',
          recommendedAgeInDays: 70,
          isRequired: true,
        ));
      }

      // 12-16 hafta: Üçüncü karma aşı + Kuduz
      if (ageInDays >= 84 && ageInDays < 112) {
        vaccines.add(const VaccineSchedule(
          name: 'Üçüncü Karma Aşı (FVRCP)',
          description: 'Karma aşının son tekrarı',
          recommendedAgeInDays: 84,
          isRequired: true,
        ));
        vaccines.add(const VaccineSchedule(
          name: 'Kuduz Aşısı',
          description: 'İlk kuduz aşısı',
          recommendedAgeInDays: 84,
          isRequired: true,
        ));
      }
    }

    // 1 yaş: Yıllık aşılar
    if (ageInMonths >= 12 && ageInMonths < 14) {
      vaccines.add(const VaccineSchedule(
        name: 'Yıllık Karma Aşı (FVRCP)',
        description: 'Yıllık karma aşı tekrarı',
        recommendedAgeInDays: 365,
        isRequired: true,
      ));
      vaccines.add(const VaccineSchedule(
        name: 'Yıllık Kuduz Aşısı',
        description: 'Yıllık kuduz aşısı tekrarı',
        recommendedAgeInDays: 365,
        isRequired: true,
      ));
    }

    // Yetişkin kedi (2+ yaş): Her yıl yıllık aşılar
    if (ageInMonths >= 24) {
      final yearsSinceLast = (ageInDays % 365);
      if (yearsSinceLast < 30 || yearsSinceLast > 335) {
        vaccines.add(const VaccineSchedule(
          name: 'Yıllık Karma Aşı (FVRCP)',
          description: 'Yıllık karma aşı tekrarı',
          recommendedAgeInDays: 365,
          isRequired: true,
        ));
        vaccines.add(const VaccineSchedule(
          name: 'Yıllık Kuduz Aşısı',
          description: 'Yıllık kuduz aşısı tekrarı',
          recommendedAgeInDays: 365,
          isRequired: true,
        ));
      }
    }

    // İsteğe bağlı: FeLV (Feline Leukemia Virus)
    vaccines.add(const VaccineSchedule(
      name: 'FeLV Aşısı',
      description: 'Dışarı çıkan kediler için önerilir',
      recommendedAgeInDays: 84,
      isRequired: false,
      additionalInfo: 'Veteriner hekiminize danışın',
    ));

    return vaccines;
  }

  /// Kuş aşı takvimi (çoğunlukla özel durumlar için)
  static List<VaccineSchedule> _getBirdVaccines(int ageInDays, int ageInMonths) {
    final vaccines = <VaccineSchedule>[];

    // Kuşlar için genel aşılar sınırlıdır, çoğunlukla veteriner kontrolü önemlidir
    vaccines.add(const VaccineSchedule(
      name: 'Veteriner Sağlık Kontrolü',
      description: 'Düzenli sağlık kontrolü (aşı yerine)',
      recommendedAgeInDays: 180,
      isRequired: false,
      additionalInfo: 'Kuşlar için rutin aşılar yaygın değildir',
    ));

    return vaccines;
  }

  /// Tavşan aşı takvimi
  static List<VaccineSchedule> _getRabbitVaccines(int ageInDays, int ageInMonths) {
    final vaccines = <VaccineSchedule>[];

    // Tavşanlar için önemli aşı: Myxomatosis ve VHD
    if (ageInDays >= 56) {
      vaccines.add(const VaccineSchedule(
        name: 'Myxomatosis Aşısı',
        description: 'Tavşanlarda önemli koruyucu aşı',
        recommendedAgeInDays: 56,
        isRequired: true,
        additionalInfo: 'Yılda 1 kez tekrarlanmalı',
      ));
      vaccines.add(const VaccineSchedule(
        name: 'VHD (Viral Hemorajik Hastalık) Aşısı',
        description: 'Tavşanlarda önemli koruyucu aşı',
        recommendedAgeInDays: 56,
        isRequired: true,
        additionalInfo: 'Yılda 1 kez tekrarlanmalı',
      ));
    }

    // Yıllık tekrar
    if (ageInMonths >= 12) {
      final yearsSinceLast = (ageInDays % 365);
      if (yearsSinceLast < 30 || yearsSinceLast > 335) {
        vaccines.add(const VaccineSchedule(
          name: 'Yıllık Myxomatosis Aşısı',
          description: 'Myxomatosis aşısı tekrarı',
          recommendedAgeInDays: 365,
          isRequired: true,
        ));
        vaccines.add(const VaccineSchedule(
          name: 'Yıllık VHD Aşısı',
          description: 'VHD aşısı tekrarı',
          recommendedAgeInDays: 365,
          isRequired: true,
        ));
      }
    }

    return vaccines;
  }

  /// Hamster aşı takvimi (çoğunlukla aşı yok, sadece kontrol)
  static List<VaccineSchedule> _getHamsterVaccines(int ageInDays, int ageInMonths) {
    final vaccines = <VaccineSchedule>[];

    // Hamsterlar için rutin aşılar yaygın değildir
    vaccines.add(const VaccineSchedule(
      name: 'Veteriner Sağlık Kontrolü',
      description: 'Düzenli sağlık kontrolü',
      recommendedAgeInDays: 180,
      isRequired: false,
      additionalInfo: 'Hamsterlar için rutin aşılar yaygın değildir',
    ));

    return vaccines;
  }

  /// Pet için yaklaşan aşıları döndürür (geçmişte kalanlar hariç)
  static List<VaccineSchedule> getUpcomingVaccines(PetModel pet) {
    final allVaccines = getRecommendedVaccines(pet);
    final ageInDays = pet.ageInDays;

    // Sadece yaşı gelmiş veya gelecek olan aşıları döndür
    return allVaccines.where((vaccine) {
      // Eğer aşı yaşı geçmişse ve zorunluysa göster (yapılmamış olabilir)
      if (vaccine.isRequired) {
        return ageInDays >= vaccine.recommendedAgeInDays - 7; // 7 gün önceden göster
      }
      // İsteğe bağlı aşılar için sadece yaşı gelmiş olanları göster
      return ageInDays >= vaccine.recommendedAgeInDays - 7;
    }).toList();
  }
}
