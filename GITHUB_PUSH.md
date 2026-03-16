# PetAI Projesini GitHub'a Atma

Proje yerel git deposuna alındı ve ilk commit yapıldı. GitHub'a atmak için:

## 1. GitHub'da yeni repo oluştur

1. https://github.com/new adresine git
2. **Repository name:** `PetAI` (veya istediğin isim, örn. `pet-ai`)
3. **Description:** (isteğe bağlı) "AI-powered pet tracking app with Flutter & Supabase"
4. **Public** seç
5. **README, .gitignore, license ekleme** – projede zaten var
6. **Create repository** tıkla

## 2. Remote ekleyip push et

GitHub repo sayfasında çıkan adresi kopyala (örn. `https://github.com/KULLANICI_ADIN/PetAI.git`), sonra terminalde:

```powershell
cd "c:\Users\fatii\Desktop\Apps\PetAI"

# GitHub repo URL'ini kendi kullanıcı adınla değiştir
git remote add origin https://github.com/KULLANICI_ADIN/PetAI.git

# İsteğe bağlı: varsayılan branch adını main yap (GitHub önerisi)
git branch -M main

# İlk push
git push -u origin main
```

**Not:** Eğer GitHub'da repo oluştururken README eklediysen önce `git pull origin main --rebase` yapıp sonra `git push -u origin main` yapman gerekebilir.

## SSH kullanıyorsan

```powershell
git remote add origin git@github.com:KULLANICI_ADIN/PetAI.git
git branch -M main
git push -u origin main
```

## Önemli

- **env.json** ve **env.release.json** `.gitignore`'da; API anahtarların repoya gitmez.
- İleride değişiklikleri göndermek için: `git add .` → `git commit -m "mesaj"` → `git push`
