#!/bin/bash

# Basit Git History Temizleme
# n8n klasörünü git history'den kaldırır

echo "🔧 n8n klasörü git history'den kaldırılıyor..."

# git filter-branch kullanarak (eski ama her yerde çalışır)
git filter-branch --force --index-filter \
  "git rm -rf --cached --ignore-unmatch n8n/tryon-workflow-with-supabase.json n8n/tryon-workflow-multi-garment.json" \
  --prune-empty --tag-name-filter cat -- --all

# Referansları temizle
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "✅ Temizleme tamamlandı!"
echo ""
echo "📤 Şimdi force push yapın:"
echo "   git push --force --all"
