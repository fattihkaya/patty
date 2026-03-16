# Görev Atama Mantığı

## Nasıl Çalışıyor?

### 1. Otomatik Atama (Pet Oluşturulduğunda)
Pet oluşturulduğunda, database trigger'ı (`assign_tasks_to_new_pet`) otomatik olarak çalışır:

**Atama Kriterleri:**
- ✅ Pet türüne göre (Köpek → dog, Kedi → cat, vb.)
- ✅ Pet cinsine göre (breed eşleşmesi veya genel görevler)
- ✅ Sadece aktif görevler (`is_active = true`)

**Filtreleme Mantığı:**
```sql
WHERE pet_type = normalized_type 
AND is_active = true
AND (breed IS NULL OR breed = pet_breed)
```

Bu mantık şu anlama gelir:
- **Genel görevler** (breed = NULL): Tüm cinsler için geçerli
- **Cins özel görevler** (breed = 'Golden Retriever'): Sadece o cinse özel

### 2. Görev Gösterimi
Görevler sayfasında gösterilen görevler:
- Pet'in türüne uygun görevler
- Pet'in cinsine uygun görevler (varsa)
- Genel görevler (breed = NULL)

### 3. Kullanıcı Özelleştirmesi
Kullanıcılar görevleri özelleştirebilir:
- ✅ Özel isim
- ✅ Özel açıklama
- ✅ Özel sıklık (frequency)
- ✅ Notlar ekleme
- ✅ Görevi aktif/pasif yapma

## Örnek Senaryo

**Pet:** Golden Retriever (Köpek)

**Atanan Görevler:**
1. ✅ Tüm köpek görevleri (genel)
   - Aşı Kontrolü (breed = NULL)
   - Veteriner Kontrolü (breed = NULL)
   - Tırnak Kesimi (breed = NULL)
   - vb.

2. ✅ Golden Retriever özel görevler (varsa)
   - Özel bakım görevleri (breed = 'Golden Retriever')

## Notlar

- Yeni pet eklendiğinde görevler otomatik atanır
- Mevcut petler için görevler manuel eklenebilir
- Görevler `pet_task_assignments` tablosunda saklanır
- Her görev pet'e özel özelleştirilebilir
