# Bugfix Gereksinimleri Dökümanı

## Giriş

n8n workflow dosyası (`n8n/tryon-workflow-with-supabase.json`) içerisinde Supabase API anahtarları (anon key ve service_role key) hardcoded olarak bulunmakta ve bu dosya GitHub'a push edilmiştir. Bu durum kritik bir güvenlik açığı oluşturmaktadır çünkü:

- **Supabase anon key**: Herkese açık olarak kullanılabilir ancak RLS (Row Level Security) politikaları ile korunmalıdır
- **Supabase service_role key**: Tüm RLS politikalarını bypass eder ve tam veritabanı erişimi sağlar - bu anahtarın ifşa olması kritik güvenlik riski oluşturur

Dosya 2 commit'te GitHub'a push edilmiş ve public repository'de erişilebilir durumdadır:
- Commit 4ef604d: "Add n8n workflows" 
- Commit bcc92f9: "requiremenets created for ai generation screen"

Bu bug, hassas API anahtarlarının git history'sinden tamamen temizlenmesini, anahtarların yenilenmesini ve gelecekte benzer ifşaların önlenmesini gerektirmektedir.

## Bug Analizi

### Mevcut Davranış (Hata)

1.1 WHEN n8n workflow dosyası repository'de bulunduğunda THEN sistem Supabase anon key'i dosya içinde hardcoded olarak saklar (eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxY3RkaWVmeHFvcmlmc294cG5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NzIxNjgsImV4cCI6MjA5MTA0ODE2OH0.rvhoSpkmSRMgab7b2T769lkTsNgoXDkxgfEoQIrhT_Y)

1.2 WHEN n8n workflow dosyası repository'de bulunduğunda THEN sistem Supabase service_role key'i dosya içinde hardcoded olarak saklar (eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndxY3RkaWVmeHFvcmlmc294cG5qIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTQ3MjE2OCwiZXhwIjoyMDkxMDQ4MTY4fQ.ClEE1CuHrTpBdJ-mPYVjCAywajxQyCak3cr2dTHqKRo)

1.3 WHEN n8n workflow dosyası git'e commit edildiğinde THEN sistem hassas API anahtarlarını git history'sine kaydeder

1.4 WHEN git history GitHub'a push edildiğinde THEN sistem hassas API anahtarlarını public repository'de erişilebilir hale getirir

1.5 WHEN .gitignore dosyası n8n/ dizinini ignore ettiğinde THEN sistem daha önce commit edilmiş n8n dosyalarını git history'sinden otomatik olarak kaldırmaz

### Beklenen Davranış (Doğru)

2.1 WHEN n8n workflow dosyası repository'de bulunduğunda THEN sistem Supabase API anahtarlarını environment variables veya güvenli credential management sistemi üzerinden referans etmelidir

2.2 WHEN hassas credential'lar içeren dosyalar git'e commit edilmeye çalışıldığında THEN sistem bu dosyaları git history'sine eklememeli ve uyarı vermelidir

2.3 WHEN daha önce commit edilmiş hassas dosyalar tespit edildiğinde THEN sistem bu dosyaları git history'sinden tamamen kaldırmalıdır (git filter-repo veya BFG Repo-Cleaner kullanarak)

2.4 WHEN ifşa olmuş API anahtarları tespit edildiğinde THEN sistem bu anahtarların yenilenmesini (rotation) gerektirmelidir

2.5 WHEN .gitignore dosyası n8n/ dizinini ignore ettiğinde THEN sistem yeni n8n dosyalarının git'e eklenmesini engellemeli ve mevcut dosyaları history'den temizlemelidir

2.6 WHEN n8n workflow'u çalıştırıldığında THEN sistem API anahtarlarını güvenli bir şekilde (environment variables veya n8n credentials store) kullanmalıdır

### Değişmemesi Gereken Davranış (Regresyon Önleme)

3.1 WHEN .gitignore dosyasında diğer ignore pattern'ler bulunduğunda THEN sistem bu pattern'leri korumaya devam etmelidir

3.2 WHEN .env dosyası .gitignore'da ignore edildiğinde THEN sistem .env dosyasını git'e eklememeli ve bu davranış korunmalıdır

3.3 WHEN n8n workflow'u API çağrıları yaptığında THEN sistem Supabase Storage ve Media Table işlemlerini doğru şekilde gerçekleştirmeye devam etmelidir (sadece credential yönetimi değişecek)

3.4 WHEN git history temizlendikten sonra THEN sistem diğer commit'leri ve proje dosyalarını korumaya devam etmelidir

3.5 WHEN yeni commit'ler yapıldığında THEN sistem normal git workflow'unu (commit, push, pull) desteklemeye devam etmelidir
