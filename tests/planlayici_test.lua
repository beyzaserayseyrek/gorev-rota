-- tests/planlayici_test.lua
-- Planlama katmanı: süre ağırlıklı graf + gerekli kenarlar (duraklar) + ATLAS

local T = dofile("tests/yardimci.lua")
local ns = T.yukle(T.CEKIRDEK)

local function konum(kita, x, y)
    return { kita = kita, x = x, y = y }
end

local function durak(gorevId, ad, tur, k)
    return ns.DurakOlustur({ gorevId = gorevId, gorevAdi = ad, tur = tur, konum = k })
end

-- Adımlar içinde bir durağın kaçıncı sırada olduğunu bulur (yoksa nil)
local function sirasi(plan, aranan)
    for i, a in ipairs(plan.adimlar) do
        if a.durak == aranan then
            return i
        end
    end
    return nil
end

T.baslik("Planlayıcı — örnek senaryo")

local oyuncu = konum(1, 0, 0)
local kurtAl     = durak(1, "Kurt Avı", "AL", konum(1, 50, 0))
local kurtHedef  = durak(1, "Kurt Avı", "HEDEF", konum(1, 100, 0))
local kurtTeslim = durak(1, "Kurt Avı", "TESLIM", konum(1, 50, 0))
local mektupHedef  = durak(2, "Mektup", "HEDEF", konum(1, 0, 80))
local mektupTeslim = durak(2, "Mektup", "TESLIM", konum(1, 0, 10))
local uzakHedef  = durak(3, "Uzak Köy", "HEDEF", konum(1, 3000, 0))
local baskaKita  = durak(4, "Deniz Aşırı", "HEDEF", konum(2, 10, 10))
local yarimAl    = durak(5, "Yarım Görev", "AL", konum(2, 0, 0))
local yarimHedef = durak(5, "Yarım Görev", "HEDEF", konum(1, 20, 20))

local duraklar = { kurtTeslim, mektupTeslim, uzakHedef, kurtHedef, baskaKita,
                   yarimHedef, mektupHedef, kurtAl, yarimAl }
local ucuslar = {
    { ad = "Batı Kampı", konum = konum(1, 0, 20) },
    { ad = "Doğu Kulesi", konum = konum(1, 2990, 0) },
}

local planlayici = ns.Planlayici.yeni(ns.AtlasCozucu)
local plan = planlayici:planla(oyuncu, duraklar, ucuslar)

-- Planı ekrana yaz (sunumda göstermek için)
for i, a in ipairs(plan.adimlar) do
    local ad = a.durak and (a.durak.gorevAdi .. " [" .. a.tur .. "]") or ("Uç: " .. a.ad)
    print(string.format("     %2d. %-32s (+%d sn)", i, ad, math.floor(a.sure + 0.5)))
end
print(string.format("     Toplam: %d sn, çözücü: %s", math.floor(plan.toplamSure + 0.5), plan.cozucu))

T.esit(plan.cozucu, "ATLAS", "rota ATLAS ile hesaplandı")

local durakAdimi = 0
for _, a in ipairs(plan.adimlar) do
    if a.durak then
        durakAdimi = durakAdimi + 1
    end
end
T.esit(durakAdimi, 6, "ulaşılabilir 6 durağın hepsi planda")
for _, d in ipairs({ kurtAl, kurtHedef, kurtTeslim, mektupHedef, mektupTeslim, uzakHedef }) do
    T.dogru(sirasi(plan, d) ~= nil, d.gorevAdi .. " [" .. d.tur .. "] planda")
end

T.dogru(sirasi(plan, kurtAl) < sirasi(plan, kurtHedef), "Kurt Avı: önce AL sonra HEDEF")
T.dogru(sirasi(plan, kurtHedef) < sirasi(plan, kurtTeslim), "Kurt Avı: önce HEDEF sonra TESLİM")
T.dogru(sirasi(plan, mektupHedef) < sirasi(plan, mektupTeslim), "Mektup: önce HEDEF sonra TESLİM")

local ucusVar = false
for i = 1, sirasi(plan, uzakHedef) - 1 do
    if plan.adimlar[i].tur == "UCUS" then
        ucusVar = true
    end
end
T.dogru(ucusVar, "uzak durağa gitmeden önce uçuş kullanıldı")

T.esit(#plan.ulasilamaz, 3, "3 durak ulaşılamaz (başka kıta / önkoşulu başka kıtada)")
local ulasilamazlar = {}
for _, d in ipairs(plan.ulasilamaz) do
    ulasilamazlar[d] = true
end
T.dogru(ulasilamazlar[baskaKita] and ulasilamazlar[yarimAl] and ulasilamazlar[yarimHedef],
    "ulaşılamayanlar doğru duraklar")
T.dogru(plan.toplamSure > 0 and plan.toplamSure < 260, "toplam süre makul (uçuşsuz yürüme ~430 sn sürerdi)")
T.esit(plan.adimlar[#plan.adimlar].durak, uzakHedef, "en uzak durak en sona kaldı (gidip dönme yok)")

T.baslik("Planlayıcı — uç durumlar")

local bos = planlayici:planla(oyuncu, {}, {})
T.esit(#bos.adimlar, 0, "durak yoksa plan boş")

local tekDurak = durak(9, "Tek", "HEDEF", konum(1, 70, 0))
local tekPlan = planlayici:planla(oyuncu, { tekDurak }, {})
T.esit(#tekPlan.adimlar, 1, "tek durakta tek adım")
T.esit(math.floor(tekPlan.adimlar[1].sure + 0.5), 10, "70 yard / 7 yard/sn = 10 sn")

T.baslik("Strategy — RotaCozucu arayüzü")
local ok = pcall(ns.Planlayici.yeni, { ad = "eksik" })
T.dogru(not ok, "coz() yöntemi olmayan çözücü reddedilir")

T.baslik("Planlayıcı — büyük senaryo (40 durak, 12 uçuş noktası)")
-- Sabit tohumlu basit sayı üreteci: her çalıştırmada aynı "rastgele" konumlar
local tohum = 12345
local function rastgele(ust)
    tohum = (tohum * 1103515245 + 12345) % 2147483648
    return tohum % ust
end
local buyukDuraklar, buyukUcuslar = {}, {}
for g = 1, 20 do
    local merkezX, merkezY = rastgele(4000), rastgele(4000)
    table.insert(buyukDuraklar, durak(100 + g, "Görev " .. g, "HEDEF", konum(1, merkezX, merkezY)))
    table.insert(buyukDuraklar, durak(100 + g, "Görev " .. g, "TESLIM",
        konum(1, merkezX + rastgele(300), merkezY + rastgele(300))))
end
for u = 1, 12 do
    table.insert(buyukUcuslar, { ad = "Uçuş " .. u, konum = konum(1, rastgele(4000), rastgele(4000)) })
end
local basla = os.clock()
local buyukPlan = planlayici:planla(konum(1, 2000, 2000), buyukDuraklar, buyukUcuslar)
local gecen = os.clock() - basla
local buyukDurakSayisi = 0
for _, a in ipairs(buyukPlan.adimlar) do
    if a.durak then
        buyukDurakSayisi = buyukDurakSayisi + 1
    end
end
print(string.format("     %d adım, toplam %d sn, hesap %.0f ms", #buyukPlan.adimlar,
    math.floor(buyukPlan.toplamSure), gecen * 1000))
T.esit(buyukDurakSayisi, 40, "40 durağın hepsi planda")
T.esit(#buyukPlan.ulasilamaz, 0, "ulaşılamayan durak yok")
T.dogru(gecen < 0.5, "hesap yarım saniyeden kısa sürdü (oyun takılmasın)")
