import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/condition_model.dart';
import 'package:pet_ai/models/log_model.dart';
import 'package:pet_ai/models/pet_model.dart';
import 'package:pet_ai/models/prepared_log_data.dart';
import 'package:pet_ai/models/pet_member.dart';
import 'package:pet_ai/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TimelineViewMode { list, calendar }

class PetProvider extends ChangeNotifier {
  static const _selectedPetPrefsKey = 'selected_pet_id';
  static const _cachedPetsPrefsKey = 'cached_pets_v1';
  static const _cachedLogsPrefsPrefix = 'cached_logs_v1_';
  static const List<_ParameterConfig> _parameterConfigs = [
    _ParameterConfig(
      key: 'fur_luster',
      label: 'Kürk Parlaklığı',
      summaryLabel: 'Kürk',
      category: 'coat',
    ),
    _ParameterConfig(
      key: 'skin_hygiene',
      label: 'Deri & Hijyen',
      summaryLabel: 'Deri',
      category: 'skin',
    ),
    _ParameterConfig(
      key: 'eye_clarity',
      label: 'Göz & Vizyon',
      summaryLabel: 'Göz',
      category: 'eye',
    ),
    _ParameterConfig(
      key: 'nasal_discharge',
      label: 'Burun / Solunum',
      summaryLabel: 'Burun',
      category: 'respiratory',
    ),
    _ParameterConfig(
      key: 'ear_posture',
      label: 'Kulak Duruşu',
      summaryLabel: 'Kulak',
      category: 'ear',
    ),
    _ParameterConfig(
      key: 'weight_index',
      label: 'Ağırlık İndeksi',
      summaryLabel: 'Kilo',
      category: 'body',
    ),
    _ParameterConfig(
      key: 'posture_alignment',
      label: 'Duruş & Omurga',
      summaryLabel: 'Duruş',
      category: 'body',
    ),
    _ParameterConfig(
      key: 'facial_relaxation',
      label: 'Mimik Rahatlığı',
      summaryLabel: 'Mimik',
      category: 'vital',
    ),
    _ParameterConfig(
      key: 'energy_vibe',
      label: 'Enerji Işığı',
      summaryLabel: 'Enerji',
      category: 'vital',
    ),
    _ParameterConfig(
      key: 'stress_level',
      label: 'Stres Düzeyi',
      summaryLabel: 'Stres',
      category: 'stress',
    ),
  ];

  final List<PetModel> _pets = [];
  final Map<String, List<LogModel>> _logsPerPet = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _likedByMe = {};
  final Map<String, List<ConditionModel>> _chronicConditionsPerPet = {};
  final Map<String, List<PetMember>> _membersPerPet = {};
  final Map<String, List<AISuggestedTask>> _aiSuggestedTasksPerPet = {};
  bool _isLoading = false;
  bool _isLoadingLogs = false;
  String? _selectedPetId;
  TimelineViewMode _viewMode = TimelineViewMode.list;
  bool _isFabExpanded = true;
  SharedPreferences? _prefs;

  PetProvider() {
    _restorePersistedSelection();
  }

  String? _buildChronicSummary(String petId) {
    final chronic = _chronicConditionsPerPet[petId];
    if (chronic == null || chronic.isEmpty) return null;

    final bullets = chronic.take(5).map((condition) {
      final note = (condition.note?.trim().isNotEmpty ?? false)
          ? ' - ${condition.note!.trim()}'
          : '';
      return '${condition.label}$note';
    }).join('; ');

    return 'Onaylı kronik durumlar: $bullets. Bu noktalar zaten takip altında, yeniden teşhis veya veteriner yönlendirmesi yapma.';
  }

  Future<void> fetchChronicConditions(String petId) async {
    try {
      final response = await SupabaseConfig.client
          .from('pet_conditions')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      _chronicConditionsPerPet[petId] = (response as List)
          .map((json) => ConditionModel.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Chronic conditions fetch failed: $e');
    }
  }

  Future<List<PetMember>> fetchMembers(String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('fetchMembers skipped: no auth session');
        return const [];
      }
      final response = await SupabaseConfig.client
          .from('pet_members')
          .select(
              'pet_id, user_id, role, added_by, created_at, profiles!user_id(email)')
          .eq('pet_id', petId);
      final members =
          (response as List).map((json) => PetMember.fromJson(json)).toList();
      _membersPerPet[petId] = members;
      notifyListeners();
      return members;
    } catch (e) {
      debugPrint('fetchMembers failed: $e');
      _logSupabaseError(e);
      return const [];
    }
  }

  Future<void> addMember(String petId, String userId,
      {String role = 'viewer'}) async {
    try {
      final email = userId.trim().toLowerCase();
      if (email.isEmpty) throw Exception('Email boş olamaz');
      // lookup user id by email (case-insensitive)
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .ilike('email', email)
          .maybeSingle();
      final targetUserId = profile?['id'] as String?;
      if (targetUserId == null) {
        throw Exception('Email bulunamadı: $email');
      }
      await SupabaseConfig.client.from('pet_members').upsert(
        {
          'pet_id': petId,
          'user_id': targetUserId,
          'role': role,
        },
        onConflict: 'pet_id,user_id',
      );
      await fetchMembers(petId);
    } catch (e) {
      debugPrint('addMember failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  void _logSupabaseError(Object e) {
    if (e is PostgrestException) {
      debugPrint(
          'PostgrestException: ${e.message} code=${e.code} details=${e.details} hint=${e.hint}');
    } else {
      debugPrint('Error: $e');
    }
  }

  Future<void> removeMember(String petId, String userId) async {
    try {
      await SupabaseConfig.client
          .from('pet_members')
          .delete()
          .eq('pet_id', petId)
          .eq('user_id', userId);
      await fetchMembers(petId);
    } catch (e) {
      debugPrint('removeMember failed: $e');
      rethrow;
    }
  }

  Future<void> _ensureChronicConditionsLoaded(String petId) async {
    if (_chronicConditionsPerPet.containsKey(petId)) return;
    await fetchChronicConditions(petId);
  }

  List<PetModel> get pets => _pets;
  bool get isLoading => _isLoading;
  bool get isLoadingLogs => _isLoadingLogs;
  String? get selectedPetId => _selectedPetId;
  TimelineViewMode get viewMode => _viewMode;
  bool get isFabExpanded => _isFabExpanded;
  List<ConditionModel> chronicConditions(String petId) =>
      _chronicConditionsPerPet[petId] ?? const [];
  List<PetMember> membersOf(String petId) => _membersPerPet[petId] ?? const [];
  Map<String, double?> averageParameterScores(String petId) {
    final logs = _logsPerPet[petId] ?? [];
    if (logs.isEmpty) return const {};

    final averages = <String, double?>{};
    for (final config in _parameterConfigs) {
      final values =
          logs.map((log) => log.scoreFor(config.key)).whereType<int>().toList();
      if (values.isEmpty) {
        averages[config.key] = null;
      } else {
        averages[config.key] = values.reduce((a, b) => a + b) / values.length;
      }
    }
    return averages;
  }

  Map<String, List<double>> parameterTrendSeries(String petId,
      {int window = 7}) {
    final logs = _logsPerPet[petId] ?? [];
    if (logs.isEmpty) return const {};

    final sampled = logs.take(window).toList().reversed.toList();
    final trend = <String, List<double>>{};
    for (final config in _parameterConfigs) {
      final series = <double>[];
      for (final log in sampled) {
        final value = log.scoreFor(config.key);
        if (value != null) {
          series.add(value.toDouble());
        }
      }
      if (series.isNotEmpty) {
        trend[config.key] = series;
      }
    }
    return trend;
  }

  List<double> moodTrendSeries(String petId, {int window = 7}) {
    final logs = _logsPerPet[petId] ?? [];
    if (logs.isEmpty) return const [];
    final sampled = logs.take(window).toList().reversed.toList();
    return sampled
        .map((log) => log.moodScore)
        .whereType<int>()
        .map((value) => value.toDouble())
        .toList();
  }

  /// Pet için genel sağlık skoru hesapla (1-10 arası)
  /// Tüm parametrelerin ortalaması alınır ve 2 ile çarpılarak 10'luk sisteme çevrilir
  double? calculateHealthScore(String petId) {
    final logs = _logsPerPet[petId] ?? [];
    if (logs.isEmpty) return null;

    // Son 7 log'un ortalamasını al
    final recentLogs = logs.take(7).toList();
    final allScores = <double>[];

    for (final log in recentLogs) {
      final scores = <double>[];

      // 10 parametre skorlarını topla
      for (final config in _parameterConfigs) {
        final score = log.scoreFor(config.key);
        if (score != null) {
          scores.add(score.toDouble());
        }
      }

      // Mood ve energy skorlarını da ekle
      if (log.moodScore != null) {
        scores.add(log.moodScore!.toDouble());
      }
      if (log.energyScore != null) {
        scores.add(log.energyScore!.toDouble());
      }

      if (scores.isNotEmpty) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        allScores.add(avg);
      }
    }

    if (allScores.isEmpty) return null;

    // Ortalama skoru hesapla ve 10'luk sisteme çevir (5'lik sistem * 2)
    final overallAvg = allScores.reduce((a, b) => a + b) / allScores.length;
    return (overallAvg * 2).clamp(1.0, 10.0);
  }

  List<double> energyTrendSeries(String petId, {int window = 7}) {
    final logs = _logsPerPet[petId] ?? [];
    if (logs.isEmpty) return const [];
    final sampled = logs.take(window).toList().reversed.toList();
    return sampled
        .map((log) => log.energyScore)
        .whereType<int>()
        .map((value) => value.toDouble())
        .toList();
  }

  void setFabExpanded(bool expanded) {
    if (_isFabExpanded != expanded) {
      _isFabExpanded = expanded;
      notifyListeners();
    }
  }

  void setViewMode(TimelineViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  PetModel? get selectedPet => _pets.isEmpty
      ? null
      : _pets.firstWhere((p) => p.id == _selectedPetId,
          orElse: () => _pets.first);

  void setSelectedPet(String? id) {
    _selectedPetId = id;
    _persistSelectedPetId(id);
    if (id != null) {
      fetchLogs(id);
      fetchChronicConditions(id);
    }
    notifyListeners();
  }

  List<LogModel> getLogsForPet(String petId) => _logsPerPet[petId] ?? [];
  int likeCountFor(String logId) => _likeCounts[logId] ?? 0;
  bool likedByMe(String logId) => _likedByMe[logId] ?? false;

  Future<void> toggleLike(String logId) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final currentlyLiked = likedByMe(logId);
    // optimistic update
    _likedByMe[logId] = !currentlyLiked;
    _likeCounts[logId] = (_likeCounts[logId] ?? 0) + (currentlyLiked ? -1 : 1);
    notifyListeners();

    try {
      if (currentlyLiked) {
        await SupabaseConfig.client
            .from('log_likes')
            .delete()
            .eq('log_id', logId)
            .eq('user_id', userId);
      } else {
        await SupabaseConfig.client.from('log_likes').insert({
          'log_id': logId,
          'user_id': userId,
        });
      }
    } catch (e) {
      // revert on failure
      _likedByMe[logId] = currentlyLiked;
      _likeCounts[logId] =
          (_likeCounts[logId] ?? 0) + (currentlyLiked ? 1 : -1);
      notifyListeners();
      debugPrint('toggleLike failed: $e');
    }
  }

  Future<void> fetchPets() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('fetchPets skipped: no auth session');
        return;
      }

      final ownerPets = await SupabaseConfig.client
          .from('pets')
          .select()
          .eq('owner_id', userId);

      final memberPetsRows = await SupabaseConfig.client
          .from('pet_members')
          .select('pets(*)')
          .eq('user_id', userId);

      final merged = <PetModel>[];
      merged.addAll(
          (ownerPets as List).map((json) => PetModel.fromJson(json)).toList());
      for (final row in (memberPetsRows as List)) {
        final petJson = row['pets'] as Map<String, dynamic>?;
        if (petJson != null) {
          merged.add(PetModel.fromJson(petJson));
        }
      }

      // unique by id
      final unique = <String, PetModel>{};
      for (final pet in merged) {
        unique[pet.id] = pet;
      }

      _pets
        ..clear()
        ..addAll(unique.values);

      // Cache pets for offline-first read
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        final encoded = jsonEncode(_pets.map((p) => p.toJson()).toList());
        await prefs.setString(_cachedPetsPrefsKey, encoded);
      } catch (e) {
        debugPrint('cache pets failed: $e');
      }

      if (_pets.isNotEmpty) {
        final persistedId = _selectedPetId;
        if (persistedId != null && _pets.any((p) => p.id == persistedId)) {
          fetchLogs(persistedId);
        } else {
          setSelectedPet(_pets.first.id);
        }
      } else {
        setSelectedPet(null);
      }
    } catch (e) {
      debugPrint('fetchPets failed: $e');
      _logSupabaseError(e);

      // Offline fallback: load cached pets
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        final raw = prefs.getString(_cachedPetsPrefsKey);
        if (raw != null && raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            final cached = decoded
                .whereType<Map>()
                .map((m) => PetModel.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            if (cached.isNotEmpty) {
              _pets
                ..clear()
                ..addAll(cached);
              // keep selection logic consistent
              if (_selectedPetId == null || !_pets.any((p) => p.id == _selectedPetId)) {
                _selectedPetId = _pets.first.id;
              }
              notifyListeners();
            }
          }
        }
      } catch (cacheErr) {
        debugPrint('load cached pets failed: $cacheErr');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yeni pet ekler. Başarılı olursa oluşturulan [PetModel] döner (ilk post için kullanılır).
  Future<PetModel?> addPet(PetModel pet, XFile imageFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Upload image to Storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_pet.jpg';
      final path = 'pet-photos/$userId/$fileName';

      final bytes = await imageFile.readAsBytes();
      await SupabaseConfig.client.storage
          .from('pets_bucket')
          .uploadBinary(path, bytes);
      final photoUrl =
          SupabaseConfig.client.storage.from('pets_bucket').getPublicUrl(path);

      // 2. Save to Database and get created row
      final petData = {
        'owner_id': userId,
        'name': pet.name,
        'type': pet.type,
        'breed': pet.breed,
        'birth_date': pet.birthDate.toIso8601String(),
        'photo_url': photoUrl,
        'weight': pet.weight,
        'gender': pet.gender,
        'energy_level': pet.energyLevel,
      };

      final inserted = await SupabaseConfig.client
          .from('pets')
          .insert(petData)
          .select()
          .single();
      final createdPet = PetModel.fromJson(inserted);
      await fetchPets();
      return createdPet;
    } catch (e) {
      debugPrint('addPet failed: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePet(PetModel pet, {XFile? newPhoto}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final updates = {
        'name': pet.name,
        'type': pet.type,
        'breed': pet.breed,
        'birth_date': pet.birthDate.toIso8601String(),
        'weight': pet.weight,
        'gender': pet.gender,
        'energy_level': pet.energyLevel,
      };

      if (newPhoto != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${pet.id}.jpg';
        final path = 'pet-photos/$userId/$fileName';
        final bytes = await newPhoto.readAsBytes();
        await SupabaseConfig.client.storage
            .from('pets_bucket')
            .uploadBinary(path, bytes);
        final photoUrl = SupabaseConfig.client.storage
            .from('pets_bucket')
            .getPublicUrl(path);
        updates['photo_url'] = photoUrl;
      }

      await SupabaseConfig.client
          .from('pets')
          .update(updates)
          .eq('id', pet.id)
          .eq('owner_id', userId);

      await fetchPets();
      if (_pets.any((element) => element.id == pet.id)) {
        setSelectedPet(pet.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLogs(String petId) async {
    _isLoadingLogs = true;
    notifyListeners();
    try {
      final response = await SupabaseConfig.client
          .from('daily_logs')
          .select('*, log_likes(count)')
          .eq('pet_id', petId)
          .order('created_at', ascending: false);

      final logs =
          (response as List).map((json) => LogModel.fromJson(json)).toList();
      _logsPerPet[petId] = logs;

      // Cache logs for offline-first read
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        final encoded = jsonEncode(logs.map((l) => l.toJson()).toList());
        await prefs.setString('$_cachedLogsPrefsPrefix$petId', encoded);
      } catch (e) {
        debugPrint('cache logs failed: $e');
      }

      // Fetch like counts per log
      for (final json in response) {
        final logId = json['id'] as String?;
        if (logId == null) continue;
        final likesWrapper = json['log_likes'] as List?;
        if (likesWrapper != null && likesWrapper.isNotEmpty) {
          final count = likesWrapper.first['count'] as int? ?? 0;
          _likeCounts[logId] = count;
        } else {
          _likeCounts[logId] = 0;
        }
      }

      // Whether current user liked
      if (SupabaseConfig.client.auth.currentUser?.id != null) {
        final userId = SupabaseConfig.client.auth.currentUser!.id;
        final logIds = logs.map((e) => e.id).toList();
        if (logIds.isNotEmpty) {
          final likedResponse = await SupabaseConfig.client
              .from('log_likes')
              .select('log_id')
              .eq('user_id', userId)
              .filter('log_id', 'in', logIds);
          for (final row in (likedResponse as List)) {
            final id = row['log_id'] as String?;
            if (id != null) _likedByMe[id] = true;
          }
        }
      }
      await fetchChronicConditions(petId);
    } catch (e) {
      debugPrint('Logs fetch failed: $e');

      // Offline fallback: load cached logs
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        final raw = prefs.getString('$_cachedLogsPrefsPrefix$petId');
        if (raw != null && raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            final cachedLogs = decoded
                .whereType<Map>()
                .map((m) => LogModel.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            _logsPerPet[petId] = cachedLogs;
            notifyListeners();
          }
        }
      } catch (cacheErr) {
        debugPrint('load cached logs failed: $cacheErr');
      }
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  Future<void> deleteLog(String logId, String petId) async {
    try {
      await SupabaseConfig.client.from('daily_logs').delete().eq('id', logId);
      final logs = _logsPerPet[petId] ?? [];
      _logsPerPet[petId] = logs.where((log) => log.id != logId).toList();
      _likeCounts.remove(logId);
      _likedByMe.remove(logId);
      notifyListeners();
    } catch (e) {
      debugPrint('deleteLog failed: $e');
      rethrow;
    }
  }

  Future<PreparedLogData> prepareLogDraft(String petId, XFile imageFile,
      {String languageCode = 'tr'}) async {
    _isLoadingLogs = true;
    notifyListeners();
    try {
      final pet = _pets.firstWhere((p) => p.id == petId);
      final age = DateTime.now().year - pet.birthDate.year;
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı oturum bilgisi bulunamadı');
      }
      await _ensureChronicConditionsLoaded(petId);

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_log.jpg';
      final path = 'daily-logs/$petId/$fileName';
      final bytes = await imageFile.readAsBytes();
      await SupabaseConfig.client.storage
          .from('pets_bucket')
          .uploadBinary(path, bytes);
      final photoUrl =
          SupabaseConfig.client.storage.from('pets_bucket').getPublicUrl(path);

      final recentState = _buildRecentStateSummary(petId);
      final profileNote = await loadPetNote(petId);
      final aiComment = await AIService.analyzePetPhoto(
        imageFile,
        petName: pet.name,
        petAge: age,
        recentState: recentState,
        profileNote: profileNote,
        languageCode: languageCode,
      );
      final cleanedComment = _extractJsonPayload(aiComment);
      Map<String, dynamic>? parsedJson;
      try {
        parsedJson = jsonDecode(cleanedComment) as Map<String, dynamic>?;
      } catch (_) {
        parsedJson = null;
      }

      final parameterScores = <String, int?>{};
      final parameterNotes = <String, String?>{};
      for (final config in _parameterConfigs) {
        parameterScores[config.key] = _extractScore(parsedJson, config.key);
        parameterNotes[config.key] = _extractNote(parsedJson, config.key);
      }

      final aiConditions = _buildConditionsFromParsed(parsedJson);
      final filteredConditions =
          _filterKnownChronic(petId, aiConditions, parsedJson);

      return PreparedLogData(
        petId: petId,
        photoUrl: photoUrl,
        aiComment: parsedJson != null ? jsonEncode(parsedJson) : cleanedComment,
        aiConditions: filteredConditions,
        parsedAiJson: parsedJson,
        parameterScores: parameterScores,
        parameterNotes: parameterNotes,
      );
    } catch (e) {
      debugPrint('prepareLogDraft failed: $e');
      rethrow;
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  Future<void> submitLogDraft(
    PreparedLogData draft, {
    String? healthNote,
    List<ConditionModel> confirmedConditions = const [],
    String visibility = 'members',
  }) async {
    _isLoadingLogs = true;
    notifyListeners();
    try {
      final persistedChronic = chronicConditions(draft.petId);
      final combinedChronic =
          _mergeConditions(persistedChronic, confirmedConditions);

      final insertPayload = {
        'pet_id': draft.petId,
        'photo_url': draft.photoUrl,
        'ai_comment': draft.aiComment,
        'health_note': healthNote,
        'ai_conditions': draft.aiConditions.map((c) => c.toJson()).toList(),
        'confirmed_conditions': combinedChronic.map((c) => c.toJson()).toList(),
        'parameter_scores': draft.parameterScores,
        'parameter_notes': draft.parameterNotes,
        'visibility': visibility,
      };

      final inserted = await SupabaseConfig.client
          .from('daily_logs')
          .insert(insertPayload)
          .select()
          .single();

      if (confirmedConditions.isNotEmpty) {
        final List<Map<String, dynamic>> conditionsPayload =
            confirmedConditions.map((condition) {
          return {
            'pet_id': draft.petId,
            'source_log_id': inserted['id'],
            'label': condition.label,
            'category': condition.category,
            'note': condition.note ?? healthNote,
          };
        }).toList();

        await SupabaseConfig.client
            .from('pet_conditions')
            .insert(conditionsPayload);
      }

      await fetchLogs(draft.petId);
      await fetchChronicConditions(draft.petId);

      // Generate AI task suggestions from analysis
      if (draft.parsedAiJson != null) {
        final pet = _pets.firstWhere((p) => p.id == draft.petId);
        await _generateAITaskSuggestions(
          draft.petId,
          draft.parsedAiJson!,
          pet.name,
          pet.type,
        );
      }

      // Check achievements (first log, log count milestones)
      await _checkAchievements(draft.petId);
    } catch (e) {
      debugPrint('submitLogDraft failed: $e');
      rethrow;
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  /// Welcome/onboarding akışında yapılan ilk analizi, kayıt sonrası ilk post (log) olarak ekler.
  Future<void> addFirstLogFromOnboarding({
    required String petId,
    required String photoUrl,
    required String aiAnalysisJson,
  }) async {
    if (aiAnalysisJson.trim().isEmpty) return;
    _isLoadingLogs = true;
    notifyListeners();
    try {
      Map<String, dynamic>? parsedJson;
      try {
        parsedJson = jsonDecode(aiAnalysisJson) as Map<String, dynamic>?;
      } catch (_) {
        parsedJson = null;
      }

      final parameterScores = <String, int?>{};
      final parameterNotes = <String, String?>{};
      for (final config in _parameterConfigs) {
        parameterScores[config.key] = _extractScore(parsedJson, config.key);
        parameterNotes[config.key] = _extractNote(parsedJson, config.key);
      }

      final aiConditions = _buildConditionsFromParsed(parsedJson);
      final commentToStore = parsedJson != null ? jsonEncode(parsedJson) : aiAnalysisJson;

      final insertPayload = {
        'pet_id': petId,
        'photo_url': photoUrl,
        'ai_comment': commentToStore,
        'health_note': null,
        'ai_conditions': aiConditions.map((c) => c.toJson()).toList(),
        'confirmed_conditions': <Map<String, dynamic>>[],
        'parameter_scores': parameterScores,
        'parameter_notes': parameterNotes,
        'visibility': 'members',
      };

      await SupabaseConfig.client
          .from('daily_logs')
          .insert(insertPayload)
          .select()
          .single();

      await fetchLogs(petId);

      if (parsedJson != null) {
        PetModel? pet;
        for (final p in _pets) {
          if (p.id == petId) {
            pet = p;
            break;
          }
        }
        if (pet != null) {
          await _generateAITaskSuggestions(
            petId,
            parsedJson,
            pet.name,
            pet.type,
          );
        }
        await _checkAchievements(petId);
      }
    } catch (e) {
      debugPrint('addFirstLogFromOnboarding failed: $e');
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  // Generate AI task suggestions from log analysis
  Future<void> _generateAITaskSuggestions(
    String petId,
    Map<String, dynamic> aiAnalysisJson,
    String petName,
    String petType,
  ) async {
    try {
      final suggestions = await AIService.suggestTasksFromAnalysis(
        aiAnalysisJson: aiAnalysisJson,
        petName: petName,
        petType: petType,
      );

      if (suggestions.isNotEmpty) {
        _aiSuggestedTasksPerPet[petId] = suggestions;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AI görev önerisi oluşturma hatası: $e');
    }
  }

  // Get AI suggested tasks for a pet
  List<AISuggestedTask> getAISuggestedTasks(String petId) {
    return _aiSuggestedTasksPerPet[petId] ?? [];
  }

  // Remove AI suggested task (when user accepts or dismisses)
  void removeAISuggestedTask(String petId, int index) {
    final tasks = _aiSuggestedTasksPerPet[petId];
    if (tasks != null && index < tasks.length) {
      tasks.removeAt(index);
      if (tasks.isEmpty) {
        _aiSuggestedTasksPerPet.remove(petId);
      }
      notifyListeners();
    }
  }

  // Check and grant achievements after log submission
  Future<void> _checkAchievements(String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final logs = getLogsForPet(petId);

      // Check first log achievement
      if (logs.length == 1) {
        await SupabaseConfig.client.rpc(
          'check_and_grant_achievement',
          params: {
            'p_user_id': userId,
            'p_achievement_code': 'first_log',
            'p_pet_id': petId,
          },
        );
      }

      // Check log count milestones
      final totalLogCount = logs.length;
      if (totalLogCount == 10) {
        await SupabaseConfig.client.rpc(
          'check_and_grant_achievement',
          params: {
            'p_user_id': userId,
            'p_achievement_code': 'log_10',
            'p_pet_id': petId,
          },
        );
      } else if (totalLogCount == 50) {
        await SupabaseConfig.client.rpc(
          'check_and_grant_achievement',
          params: {
            'p_user_id': userId,
            'p_achievement_code': 'log_50',
            'p_pet_id': petId,
          },
        );
      } else if (totalLogCount == 100) {
        await SupabaseConfig.client.rpc(
          'check_and_grant_achievement',
          params: {
            'p_user_id': userId,
            'p_achievement_code': 'log_100',
            'p_pet_id': petId,
          },
        );
      }

      // Perfect health achievement check (all scores = 5.0)
      final latestLog = logs.firstOrNull;
      if (latestLog != null) {
        final allScores = latestLog.parameterScores.values.toList();
        if (allScores.isNotEmpty && allScores.every((score) => score == 5.0)) {
          await SupabaseConfig.client.rpc(
            'check_and_grant_achievement',
            params: {
              'p_user_id': userId,
              'p_achievement_code': 'perfect_health',
              'p_pet_id': petId,
            },
          );
        }
      }
    } on PostgrestException catch (e) {
      // RPC check_and_grant_achievement Supabase'de yoksa sessizce atla (opsiyonel özellik)
      if (e.code != 'PGRST202') debugPrint('Check achievements error: $e');
    } catch (e) {
      debugPrint('Check achievements error: $e');
    }
  }

  String _extractJsonPayload(String input) {
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

  String? _buildRecentStateSummary(String petId, {int take = 3}) {
    final logs = _logsPerPet[petId];
    final chronicSummary = _buildChronicSummary(petId);
    if ((logs == null || logs.isEmpty) && chronicSummary == null) return null;

    final buffer = StringBuffer();
    if (chronicSummary != null) {
      buffer.writeln(chronicSummary);
    }
    final recentLogs = logs?.take(take) ?? const Iterable<LogModel>.empty();
    for (final log in recentLogs) {
      final parts = <String>[];
      if (log.summaryTr != null && log.summaryTr!.trim().isNotEmpty) {
        parts.add('Özet: ${log.summaryTr!.trim()}');
      }
      if (log.moodLabel != null) {
        parts.add('Mood: ${log.moodLabel} (${log.moodScore ?? "-"} /5)');
      }
      if (log.energyScore != null) {
        parts.add('Enerji: ${log.energyScore}/5');
      }
      for (final config in _parameterConfigs) {
        final note = log.noteFor(config.key);
        if (note != null && note.trim().isNotEmpty) {
          parts.add('${config.summaryLabel}: ${note.trim()}');
        }
      }
      if (log.healthNote != null && log.healthNote!.trim().isNotEmpty) {
        parts.add('Gözlem: ${log.healthNote}');
      }
      if (log.confirmedConditions.isNotEmpty) {
        parts.add(
            'Onaylı durumlar: ${log.confirmedConditions.map((c) => c.label).join(", ")}');
      }
      if (parts.isNotEmpty) {
        buffer.writeln(
            '- ${DateFormat('dd MMM', 'tr_TR').format(log.createdAt)}: ${parts.join(" | ")}');
      }
    }

    final summary = buffer.toString().trim();
    return summary.isEmpty ? null : summary;
  }

  Future<void> _restorePersistedSelection() async {
    _prefs = await SharedPreferences.getInstance();
    final storedId = _prefs!.getString(_selectedPetPrefsKey);
    if (storedId != null) {
      _selectedPetId = storedId;
      notifyListeners();
    }
  }

  void _persistSelectedPetId(String? id) {
    if (_prefs != null) {
      _writeSelection(_prefs!, id);
    } else {
      SharedPreferences.getInstance().then((prefs) {
        _prefs = prefs;
        _writeSelection(prefs, id);
      });
    }
  }

  void _writeSelection(SharedPreferences prefs, String? id) {
    if (id == null) {
      prefs.remove(_selectedPetPrefsKey);
    } else {
      prefs.setString(_selectedPetPrefsKey, id);
    }
  }

  Future<String?> loadPetNote(String petId) async {
    try {
      final response = await SupabaseConfig.client
          .from('pets')
          .select('profile_note')
          .eq('id', petId)
          .maybeSingle();
      final note = response?['profile_note'] as String?;
      final index = _pets.indexWhere((p) => p.id == petId);
      if (index != -1) {
        _pets[index] = _pets[index].copyWith(profileNote: note);
        notifyListeners();
      }
      return note;
    } catch (e) {
      debugPrint('loadPetNote failed: $e');
      return null;
    }
  }

  Future<void> savePetNote(String petId, String? note) async {
    try {
      await SupabaseConfig.client
          .from('pets')
          .update({'profile_note': note}).eq('id', petId);
      final index = _pets.indexWhere((p) => p.id == petId);
      if (index != -1) {
        _pets[index] = _pets[index].copyWith(profileNote: note);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('savePetNote failed: $e');
    }
  }

  List<ConditionModel> _buildConditionsFromParsed(
      Map<String, dynamic>? parsed) {
    if (parsed == null) return [];
    final conditions = <ConditionModel>[];

    void addCondition({
      required String label,
      required String category,
      int? score,
      String? note,
      String? severity,
    }) {
      conditions.add(ConditionModel(
        label: label,
        category: category,
        score: score,
        note: note,
        severity: severity,
        createdAt: DateTime.now(),
      ));
    }

    for (final config in _parameterConfigs) {
      final score = _extractScore(parsed, config.key);
      final note = _extractNote(parsed, config.key);
      if (_shouldIncludeCondition(
        category: config.category,
        score: score,
        note: note,
      )) {
        addCondition(
          label: config.label,
          category: config.category,
          score: score,
          note: note,
          severity: _severityFromScore(score),
        );
      }
    }

    return conditions;
  }

  bool _shouldIncludeCondition({
    required String category,
    int? score,
    String? note,
  }) {
    final normalizedNote = note?.toLowerCase().trim() ?? '';
    const keywords = [
      'kızarıkl',
      'enfeks',
      'iltihap',
      'yar',
      'ağrı',
      'rahats',
      'problem',
      'sorun',
      'kontrol',
      'takip',
      'veteriner',
      'doktor',
      'görmüyor',
      'akıntı',
      'kör',
      'şiş',
      'mor',
      'kan',
      'kuruluk',
      'dökül',
      'zayıf',
      'düşük',
      'stres',
      'gergin',
      'kaygı',
    ];

    final noteFlag = normalizedNote.isNotEmpty &&
        keywords.any((keyword) => normalizedNote.contains(keyword));
    final scoreFlag = score != null && score <= 3;

    return noteFlag || scoreFlag;
  }

  String? _severityFromScore(int? score) {
    if (score == null) return null;
    if (score <= 2) return 'severe';
    if (score == 3) return 'moderate';
    return 'normal';
  }

  List<ConditionModel> _filterKnownChronic(
    String petId,
    List<ConditionModel> incoming,
    Map<String, dynamic>? rawAiJson,
  ) {
    final persisted = chronicConditions(petId);
    if (persisted.isEmpty) return incoming;

    bool matchesPersisted(ConditionModel condition) {
      final targetLabel = condition.label.toLowerCase().trim();
      final targetNote = condition.note?.toLowerCase().trim();
      return persisted.any((stored) =>
          _isSameCondition(stored, condition) ||
          stored.label.toLowerCase().trim() == targetLabel ||
          (targetNote != null &&
              targetNote.isNotEmpty &&
              (stored.note?.toLowerCase().contains(targetNote) ?? false)));
    }

    final filtered = incoming.where((cond) => !matchesPersisted(cond)).toList();
    return filtered;
  }

  List<ConditionModel> _mergeConditions(
    List<ConditionModel> persisted,
    List<ConditionModel> additions,
  ) {
    if (additions.isEmpty) return persisted;
    final merged = [...persisted];
    for (final condition in additions) {
      final exists =
          merged.any((stored) => _isSameCondition(stored, condition));
      if (!exists) {
        merged.add(condition);
      }
    }
    return merged;
  }

  bool _isSameCondition(ConditionModel a, ConditionModel b) {
    final labelA = a.label.toLowerCase().trim();
    final labelB = b.label.toLowerCase().trim();
    if (labelA == labelB) return true;

    final noteA = a.note?.toLowerCase().trim();
    final noteB = b.note?.toLowerCase().trim();
    if (noteA != null &&
        noteB != null &&
        noteA.isNotEmpty &&
        noteB.isNotEmpty &&
        (noteA.contains(noteB) || noteB.contains(noteA))) {
      return true;
    }
    return false;
  }

  int? _extractScore(Map<String, dynamic>? parsed, String key) {
    return (parsed?['${key}_score'] as num?)?.round();
  }

  String? _extractNote(Map<String, dynamic>? parsed, String key) {
    final direct = parsed?['${key}_note'] as String?;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    final notes = parsed?['notes'];
    if (notes is Map<String, dynamic>) {
      final fromMap = notes[key];
      if (fromMap is String && fromMap.trim().isNotEmpty) return fromMap.trim();
    }
    // Legacy fallback
    switch (key) {
      case 'fur_luster':
      case 'skin_hygiene':
        return parsed?['coat_notes_tr'] as String?;
      case 'eye_clarity':
      case 'nasal_discharge':
        return parsed?['eye_notes_tr'] as String?;
      case 'weight_index':
      case 'posture_alignment':
        return parsed?['body_notes_tr'] as String?;
      case 'stress_level':
        return parsed?['stress_trigger_tr'] as String?;
    }
    return null;
  }
}

class _ParameterConfig {
  final String key;
  final String label;
  final String summaryLabel;
  final String category;

  const _ParameterConfig({
    required this.key,
    required this.label,
    required this.summaryLabel,
    required this.category,
  });
}
