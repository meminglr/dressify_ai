# 🚨 GÜVENLİK İHLALİ - ACİL EYLEM PLANI

## Tespit Edilen Sorun
n8n workflow dosyalarında Supabase API anahtarları hardcoded olarak GitHub'a push edilmiş.

## Sızdırılan Bilgiler
- **Supabase Anon Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxY3RkaWVmeHFvcmlmc294cG5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NzIxNjgsImV4cCI6MjA5MTA0ODE2OH0.rvhoSpkmSRMgab7b2T769lkTsNgoXDkxgfEoQIrhT_Y
- **Supabase Service Role Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxY3RkaWVmeHFvcmlmc294cG5qIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTQ3MjE2OCwiZXhwIjoyMDkxMDQ4MTY4fQ.ClEE1CuHrTpBdJ-mPYVjCAywajxQyCak3cr2dTHqKRo
- **Supabase Project URL**: https://wqctdiefxqorifsoxpnj.supabase.co

## ⚠️ ACİL YAPILMASI GEREKENLER (ŞİMDİ!)

### 1. Supabase API Anahtarlarını Yenile (EN ÖNEMLİ!)
```
1. https://supabase.com/dashboard/project/wqctdiefxqorifsoxpnj/settings/api adresine git
2. "Reset API Keys" butonuna tıkla
3. Yeni anahtarları güvenli bir yere kaydet (.env dosyasına)
4. Tüm servisleri yeni anahtarlarla güncelle
```

### 2. Git History'den Hassas Dosyaları Temizle
```bash
# BFG Repo-Cleaner kullanarak (önerilen)
brew install bfg  # veya https://rtyley.github.io/bfg-repo-cleaner/
bfg --delete-folders n8n
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

### 3. Repository'yi Kontrol Et
- Eğer repository public ise, anahtarlar zaten sızdırılmış kabul edilmeli
- GitHub'da "Security" sekmesinden "Secret scanning alerts" kontrol et

## 📋 YAPILACAKLAR LİSTESİ

- [ ] Supabase API anahtarlarını YENİLE (EN ÖNCELİKLİ!)
- [ ] n8n/ klasörünü git history'den SİL
- [ ] .gitignore'a n8n/ eklendiğini DOĞRULA (zaten ekli)
- [ ] n8n workflow'larını environment variables ile YENİDEN YAPILANDIR
- [ ] Tüm servisleri yeni anahtarlarla GÜNCELLE
- [ ] RLS (Row Level Security) politikalarını KONTROL ET
- [ ] Supabase audit logs'u İNCELE (yetkisiz erişim var mı?)
- [ ] GitHub repository'yi private yap (eğer public ise)

## 🔒 Uzun Vadeli Çözüm

1. n8n workflow'larında environment variables kullan
2. Hassas bilgileri asla git'e commit etme
3. Pre-commit hooks ekle (git-secrets gibi)
4. Secret scanning araçları kullan

## 📞 İletişim
Bu belgeyi tamamladıktan sonra SİL!
