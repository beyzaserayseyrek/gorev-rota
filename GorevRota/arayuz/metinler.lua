-- arayuz/metinler.lua
-- Ekranda görünen bütün metinler ve biçimlendirme yardımcıları tek yerde.

local _, ns = ...

local Metin = {}

-- Oyunun varsayılan yazı tipinde ı, ş, ğ, İ, Ş, Ğ harfleri olmayabilir (kutucuk görünür).
-- Bu yüzden ekrana yazmadan önce en yakın harfe çeviriyoruz. (ö, ü, ç sorunsuz görünür.)
local DONUSUM = { ["ı"] = "i", ["İ"] = "I", ["ş"] = "s", ["Ş"] = "S", ["ğ"] = "g", ["Ğ"] = "G" }

function Metin.uygunla(metin)
    for turkce, yerine in pairs(DONUSUM) do
        metin = metin:gsub(turkce, yerine)
    end
    return metin
end

Metin.TUR_ADI = { AL = "Görevi al", HEDEF = "Hedef", TESLIM = "Teslim et", UCUS = "Uç" }
Metin.TUR_RENGI = { AL = "ffd100", HEDEF = "ffffff", TESLIM = "40ff40", UCUS = "66ccff" }

-- Saniyeyi okunur süreye çevirir: 45 -> "45 sn", 200 -> "3 dk 20 sn"
function Metin.sure(saniye)
    saniye = math.floor(saniye + 0.5)
    if saniye < 60 then
        return saniye .. " sn"
    end
    local dakika = math.floor(saniye / 60)
    local kalan = saniye % 60
    if kalan == 0 then
        return dakika .. " dk"
    end
    return dakika .. " dk " .. kalan .. " sn"
end

-- Bir plan adımının tek satırlık metni (renk kodsuz)
-- ör. "3. Teslim et: Kurt Avı (+1 dk 20 sn)"
function Metin.adim(sira, adim)
    local ad = adim.durak and adim.durak.gorevAdi or adim.ad
    return string.format("%d. %s: %s (+%s)", sira, Metin.TUR_ADI[adim.tur], ad, Metin.sure(adim.sure))
end

Metin.ONEK = "|cff33ccffGörevRota:|r "
Metin.KONUM_YOK = "Konumun okunamadı (zindan ya da özel bir bölgede olabilirsin)."
Metin.PLAN_YOK = "Henüz plan yok. Önce /gr plan yaz."
Metin.DURAK_YOK = "Planlanacak durak yok. Görev al ya da /gr ekle ile durak ekle."
Metin.OYUN_TAKIP = "Bu adımı oyun takip ediyor; görev ilerleyince liste kendiliğinden güncellenir."

Metin.YARDIM = {
    "Komutlar:",
    "  /gr plan  — görev duraklarını ATLAS ile sırala ve paneli aç",
    "  /gr liste — sıralı durakları sohbet penceresine yaz (/gr list de olur)",
    "  /gr panel — paneli aç / kapat",
    "  /gr ekle <al|hedef|teslim> [x y] <ad> — elle durak ekle (x y yoksa bulunduğun yer)",
    "  /gr tamam — elle eklenen sıradaki durağı tamamlandı say",
    "  /gr temizle — elle eklenen bütün durakları sil",
    "  /gr yardim — bu liste",
}

ns.Metin = Metin
