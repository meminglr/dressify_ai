# Supabase Migrations

Bu klasör Supabase veritabanı migration dosyalarını içerir.

## Migration Dosyaları

### 20260415000001_create_saved_products_table.sql
Trendyol ürünlerini kaydetmek için `saved_products` tablosunu oluşturur.

**Özellikler:**
- UUID primary key
- User ID foreign key (auth.users)
- Trendyol product ID, name, image, price, URL
- Unique constraint (user_id, product_id)
- RLS policies (SELECT, INSERT, DELETE, UPDATE)
- Indexes (user_id, saved_at, product_id)

**Rollback:** `20260415000001_create_saved_products_table_rollback.sql`

### 20260415000002_extend_media_table_for_trendyol.sql
`media` tablosunu Trendyol ürünlerini destekleyecek şekilde genişletir.

**Özellikler:**
- `media_type` enum'una `TRENDYOL_PRODUCT` değeri ekler
- `trendyol_product_id` TEXT sütunu ekler
- Index oluşturur
- Check constraint ekler

**Rollback:** `20260415000002_extend_media_table_for_trendyol_rollback.sql`

## Migration Uygulama

### Supabase CLI ile

```bash
# Tüm migration'ları uygula
supabase db push

# Belirli bir migration'ı uygula
supabase migration up --file 20260415000001_create_saved_products_table.sql
```

### Supabase Dashboard ile

1. Supabase Dashboard'a git
2. SQL Editor'ü aç
3. Migration dosyasının içeriğini kopyala
4. SQL Editor'e yapıştır ve çalıştır

## Rollback

Bir migration'ı geri almak için ilgili rollback dosyasını çalıştırın:

```bash
# SQL Editor'de rollback dosyasını çalıştır
supabase db execute --file 20260415000001_create_saved_products_table_rollback.sql
```

## Test

Migration'ları test etmek için:

```bash
# Local Supabase instance başlat
supabase start

# Migration'ları uygula
supabase db push

# Test et
supabase db test
```

## Notlar

- Migration dosyaları timestamp ile sıralanır (YYYYMMDDHHMMSS)
- Her migration için bir rollback dosyası oluşturulmalıdır
- Production'a push etmeden önce local'de test edin
- RLS policies her zaman enable edilmelidir
- Indexes performans için kritiktir
