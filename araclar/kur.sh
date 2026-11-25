#!/bin/sh
# Eklentiyi oyunun AddOns klasörüne kopyalar (macOS). Repo kökünden çalıştırın:
#   sh araclar/kur.sh            -> _retail_ (ücretsiz deneme / güncel sürüm)
#   sh araclar/kur.sh _forever_  -> WoW: Forever
# Kopyaladıktan sonra oyunda /reload yazın.
set -e
SURUM="${1:-_retail_}"
HEDEF="/Applications/World of Warcraft/$SURUM/Interface/AddOns"

if [ ! -d "/Applications/World of Warcraft/$SURUM" ]; then
    echo "Oyun klasörü bulunamadı: /Applications/World of Warcraft/$SURUM"
    echo "Oyunu bir kez açıp kapatın ya da sürüm adını kontrol edin."
    exit 1
fi

mkdir -p "$HEDEF"
rm -rf "$HEDEF/GorevRota"
cp -R GorevRota "$HEDEF/GorevRota"
echo "Kopyalandı: $HEDEF/GorevRota"
echo "Oyunda /reload yazın (oyun kapalıysa açtığınızda yüklenir)."
