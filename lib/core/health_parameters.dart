import 'package:flutter/material.dart';

class HealthParameterDescriptor {
  final String key;
  final String label;
  final String shortLabel;
  final String shortLabelEn;
  final String group;
  final Color color;
  final String description;

  const HealthParameterDescriptor({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.shortLabelEn,
    required this.group,
    required this.color,
    required this.description,
  });
}

/// Groups:
/// - care (kürk/deri/yüz/duyu)
/// - physical (kilo/postür)
/// - vitality (mimik/enerji/stres)
const List<HealthParameterDescriptor> kHealthParameters =
    <HealthParameterDescriptor>[
  HealthParameterDescriptor(
    key: 'fur_luster',
    label: 'Kürk Parlaklığı',
    shortLabel: 'Kürk',
    shortLabelEn: 'Coat',
    group: 'care',
    color: Color(0xFF38BDF8),
    description:
        'Kürk parlaklığı; yeterli beslenme, bakım ve genel sağlık durumuna işaret eder. Matlık ve dökülme eksiklik göstergesi olabilir.',
  ),
  HealthParameterDescriptor(
    key: 'skin_hygiene',
    label: 'Deri & Hijyen',
    shortLabel: 'Deri',
    shortLabelEn: 'Skin',
    group: 'care',
    color: Color(0xFF0EA5E9),
    description:
        'Deri sağlığı, parazit ve alerji kontrolü kadar düzenli temizlikle desteklenir. Kızarıklık ya da kepek, takibi gerektirebilir.',
  ),
  HealthParameterDescriptor(
    key: 'eye_clarity',
    label: 'Göz & Görüş',
    shortLabel: 'Göz',
    shortLabelEn: 'Eyes',
    group: 'care',
    color: Color(0xFF2563EB),
    description:
        'Göz parlaklığı ve netliği; iltihap, akıntı veya kaşıntı olmadığını gösterir. Bulanıklık ya da kızarıklıkta veterinere danışın.',
  ),
  HealthParameterDescriptor(
    key: 'nasal_discharge',
    label: 'Burun / Solunum',
    shortLabel: 'Burun',
    shortLabelEn: 'Nose/Breath',
    group: 'care',
    color: Color(0xFF1D4ED8),
    description:
        'Burun akıntısı olmaması; rahat solunum ve iyi oksijenlenme anlamına gelir. Hırıltı, tıkanıklık veya akıntı dikkatle izlenmelidir.',
  ),
  HealthParameterDescriptor(
    key: 'ear_posture',
    label: 'Kulak Duruşu',
    shortLabel: 'Kulak',
    shortLabelEn: 'Ears',
    group: 'care',
    color: Color(0xFF1E3A8A),
    description:
        'Kulak dikliği ve temizliği; enfeksiyon veya akar riskinin düşük olduğunu gösterir. Koku, kaşıntı veya kızarıklıkta temizlik ve kontrol şart.',
  ),
  HealthParameterDescriptor(
    key: 'weight_index',
    label: 'Ağırlık İndeksi',
    shortLabel: 'Kilo',
    shortLabelEn: 'Weight',
    group: 'physical',
    color: Color(0xFF4ADE80),
    description:
        'İdeal ağırlık, kas ve yağ dengesinin yerinde olduğunu gösterir. Hızlı kilo değişimleri hormonal ya da beslenme kaynaklı olabilir.',
  ),
  HealthParameterDescriptor(
    key: 'posture_alignment',
    label: 'Duruş & Omurga',
    shortLabel: 'Duruş',
    shortLabelEn: 'Posture',
    group: 'physical',
    color: Color(0xFF22C55E),
    description:
        'Dengeli duruş ve omurga hizası; eklem ve kas sağlığının göstergesidir. Topallama veya kamburluk ağrı işareti olabilir.',
  ),
  HealthParameterDescriptor(
    key: 'facial_relaxation',
    label: 'Mimik Rahatlığı',
    shortLabel: 'Mimik',
    shortLabelEn: 'Facial Expres.',
    group: 'vitality',
    color: Color(0xFF7C3AED),
    description:
        'Yüz ifadesi ve mimik rahatlığı; stres veya ağrı olmadığını anlatır. Sürekli gergin ifade rahatsızlık göstergesi olabilir.',
  ),
  HealthParameterDescriptor(
    key: 'energy_vibe',
    label: 'Enerji Işığı',
    shortLabel: 'Enerji',
    shortLabelEn: 'Energy',
    group: 'vitality',
    color: Color(0xFFA855F7),
    description:
        'Enerji seviyesi; oyun, merak ve günlük aktivite isteğini yansıtır. Ani düşüşler hastalık ya da yorgunluk belirtisi olabilir.',
  ),
  HealthParameterDescriptor(
    key: 'stress_level',
    label: 'Stres Düzeyi',
    shortLabel: 'Stres',
    shortLabelEn: 'Stress',
    group: 'vitality',
    color: Color(0xFFDB2777),
    description:
        'Düşük stres; güvenli çevre ve iyi bakımın işaretidir. Sürekli saklanma, aşırı yalanma veya agresyon stres sinyalleri olabilir.',
  ),
];
