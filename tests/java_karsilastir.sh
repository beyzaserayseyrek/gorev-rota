#!/bin/sh
# Hocanın Java ATLAS kodunu indirip çalıştırır, çıktısını tests/veri/java_beklenen.txt
# ile karşılaştırır. Java (JDK) ve git gerekir. Repo kökünden çalıştırın:
#   sh tests/java_karsilastir.sh
set -e
GECICI=$(mktemp -d)
git clone -q --depth 1 https://github.com/savastakan/atlas "$GECICI/atlas"
mkdir -p "$GECICI/sinif"
javac -nowarn -d "$GECICI/sinif" "$GECICI"/atlas/*.java tests/java/Referans.java 2>/dev/null
java -cp "$GECICI/sinif" Referans tests/veri/bbtas.kiss2.fsm > "$GECICI/cikti.txt"
if diff -u tests/veri/java_beklenen.txt "$GECICI/cikti.txt"; then
    echo "Java çıktısı beklenen dosya ile aynı."
else
    echo "FARK VAR: yukarıdaki satırlara bakın."
    exit 1
fi
rm -rf "$GECICI"
