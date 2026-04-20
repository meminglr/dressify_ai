#!/bin/bash

# Git History Temizleme Script'i
# Bu script n8n klasörünü git history'den tamamen kaldırır

echo "⚠️  UYARI: Bu işlem git history'yi değiştirecek!"
echo "Devam etmeden önce repository'nin bir yedeğini alın."
echo ""
read -p "Devam etmek istiyor musunuz? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "🔧 Git history temizleniyor..."

# Yöntem 1: git filter-repo (önerilen)
if command -v git-filter-repo &> /dev/null
then
    echo "git-filter-repo kullanılıyor..."
    git filter-repo --path n8n/ --invert-paths --force
    echo "✅ git-filter-repo ile temizleme tamamlandı"
else
    echo "⚠️  git-filter-repo bulunamadı. Yükleme:"
    echo "   brew install git-filter-repo"
    echo "   veya: pip install git-filter-repo"
    echo ""
    
    # Yöntem 2: BFG Repo-Cleaner
    if command -v bfg &> /dev/null
    then
        echo "BFG Repo-Cleaner kullanılıyor..."
        bfg --delete-folders n8n
        git reflog expire --expire=now --all
        git gc --prune=now --aggressive
        echo "✅ BFG ile temizleme tamamlandı"
    else
        echo "⚠️  BFG Repo-Cleaner bulunamadı. Yükleme:"
        echo "   brew install bfg"
        echo ""
        echo "❌ Hiçbir temizleme aracı bulunamadı!"
        exit 1
    fi
fi

echo ""
echo "✅ Git history temizlendi!"
echo ""
echo "📤 Şimdi force push yapmanız gerekiyor:"
echo "   git push --force --all"
echo "   git push --force --tags"
echo ""
echo "⚠️  DİKKAT: Force push yapmadan önce:"
echo "   1. Tüm team üyelerini bilgilendirin"
echo "   2. Herkesin değişikliklerini commit ettiğinden emin olun"
echo "   3. Force push sonrası herkes 'git pull --rebase' yapmalı"
