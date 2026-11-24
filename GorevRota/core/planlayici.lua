-- core/planlayici.lua
-- Planlama katmanı: görev duraklarından süre ağırlıklı bir graf kurar,
-- rota çözücüsüne (ATLAS) verir ve sonucu sıralı adım listesine çevirir.
--
-- Graf nasıl kurulur?
--   Düğümler : oyuncunun konumu, her durak, bilinen her uçuş noktası (aynı kıtada olanlar)
--   Kenarlar :
--     - yürüme : her düğüm en yakın K komşusuna bağlanır (iki yönlü), ama yalnızca
--                komşu yeterince yakınsa (komsuMesafesi); uzak yerlere uçuşla gidilsin
--     - uçuş   : bilinen uçuş noktaları arasında (iki yönlü)
--     - köprü  : graf hâlâ kopuk parçalara ayrılıyorsa, parçalar en kısa yürüme
--                kenarlarıyla birleştirilir (Kruskal yöntemi)
--     - durak  : her durak düğümünde kendine dönen bir kenar. Bunlar "gerekli kenarlar"dır;
--                ATLAS bu kenarları kapsayan bir yürüyüş arar.
--   Ağırlık  : saniye cinsinden süre (mesafe / hız)
--
-- ATLAS'a verdiğimiz değer fonksiyonu:
--   gerekli ve henüz yapılmamış bir durak kenarı  ->  ODUL - süre
--   diğer kenarlar                                ->  - süre
--
-- Kademeli ödül: ATLAS'ı birkaç tur çalıştırırız, her tur bir öncekinin bittiği yerden başlar.
--   1. tur ODUL = 60 sn  : yalnızca "1 dakikadan kısa sapma" gerektiren yakın duraklar toplanır
--   2. tur ODUL = 300 sn : biraz daha uzaktakiler (ör. kısa bir uçuşla gidilenler)
--   3. tur ODUL = çok büyük : kalan bütün duraklar (en uzaklar en sona kalır, geri dönülmez)

local _, ns = ...

local Planlayici = {}
Planlayici.__index = Planlayici

local VARSAYILAN_AYAR = {
    yurumeHizi = 7,     -- yard/saniye (koşma hızı)
    ucusHizi = 30,      -- yard/saniye (uçuş yolu, yaklaşık)
    ucusBekleme = 15,   -- saniye (binme/inme payı)
    komsuSayisi = 5,    -- her düğüm kaç yakın komşuya yürüme kenarıyla bağlansın
    komsuMesafesi = 400, -- yard; bundan uzak komşulara doğrudan yürüme kenarı kurulmaz
}

-- Her turda bir durağı tamamlamanın değeri (saniye). Son değer her yolculuktan büyük olmalı.
local ODUL_KADEMELERI = { 60, 300, 1000000 }

-- cozucu: RotaCozucu arayüzünü sağlayan nesne (ör. ns.AtlasCozucu)
function Planlayici.yeni(cozucu, ayarlar)
    local p = setmetatable({}, Planlayici)
    p.cozucu = ns.RotaCozucu.dogrula(cozucu)
    p.ayar = {}
    for ad, deger in pairs(VARSAYILAN_AYAR) do
        p.ayar[ad] = (ayarlar and ayarlar[ad]) or deger
    end
    return p
end

local function mesafe(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Her durak için önkoşullar: aynı görevin daha önceki aşamaları (AL < HEDEF < TESLIM)
local function onkosullariBul(duraklar)
    local onk = {}
    for _, d in ipairs(duraklar) do
        onk[d] = {}
        for _, e in ipairs(duraklar) do
            if e ~= d and e.gorevId == d.gorevId and ns.TurSirasi[e.tur] < ns.TurSirasi[d.tur] then
                table.insert(onk[d], e)
            end
        end
    end
    return onk
end

local function hepsiBitti(liste, bitti)
    for _, d in ipairs(liste) do
        if not bitti[d] then
            return false
        end
    end
    return true
end

-- Yolu baştan sona "yürür"; hangi durağın yolun hangi adımında tamamlandığını bulur.
-- Bir durak, önkoşulları bittikten sonra kendi kenarından ilk geçildiğinde tamamlanır.
-- 'devam' verilirse 'yol'un ardından o da yürünür (önceki turlar + şimdiki tur).
local function tamamlananlariBul(graf, yol, onk, devam)
    local bitti = {}   -- durak -> true
    local sira = {}    -- yoldaki sıra numarası -> o anda tamamlanan durak
    local i = 0
    for _, liste in ipairs({ yol, devam or {} }) do
        for _, etiket in ipairs(liste) do
            i = i + 1
            local d = graf:kenar(etiket).veri.durak
            if d and not bitti[d] and hepsiBitti(onk[d], bitti) then
                bitti[d] = true
                sira[i] = d
            end
        end
    end
    return bitti, sira
end

-- Süre ağırlıklı graf kurar.
-- Dönüş: graf, başlangıç kenarı, ulaşılamayan duraklar
function Planlayici:grafKur(oyuncu, duraklar, ucusNoktalari)
    local graf = ns.Graf.yeni()
    local noktalar = { { tur = "OYUNCU", ad = "Sen", konum = oyuncu } }
    local ulasilamaz = {}

    for _, d in ipairs(duraklar) do
        if d.konum and d.konum.kita == oyuncu.kita then
            table.insert(noktalar, { tur = "DURAK", ad = d.gorevAdi, konum = d.konum, durak = d })
        else
            table.insert(ulasilamaz, d)   -- başka kıtada ya da konumu bilinmiyor
        end
    end
    local ilkUcus = #noktalar + 1
    for _, u in ipairs(ucusNoktalari or {}) do
        if u.konum.kita == oyuncu.kita then
            table.insert(noktalar, { tur = "UCUS", ad = u.ad, konum = u.konum })
        end
    end

    local function sureBul(i, j, hiz)
        return mesafe(noktalar[i].konum, noktalar[j].konum) / hiz
    end

    -- Birleşim-bul (union-find): hangi düğümler birbirine bağlı, onu tutar.
    -- Her düğüm bir "ebeveyn"e işaret eder; aynı köke çıkan düğümler aynı parçadadır.
    local ebeveyn = {}
    for i = 1, #noktalar do
        ebeveyn[i] = i
    end
    local function kok(i)
        while ebeveyn[i] ~= i do
            i = ebeveyn[i]
        end
        return i
    end
    local function birlestir(i, j)
        ebeveyn[kok(i)] = kok(j)
    end

    -- Aynı iki düğüm arasına iki kez yürüme kenarı eklememek için
    local eklendi = {}
    local function yurumeEkle(i, j)
        local anahtar = math.min(i, j) .. "-" .. math.max(i, j)
        if i == j or eklendi[anahtar] then
            return
        end
        eklendi[anahtar] = true
        birlestir(i, j)
        local sure = sureBul(i, j, self.ayar.yurumeHizi)
        graf:kenarEkle(i, j, "yuru", nil, sure, { tur = "YURU" })
        graf:kenarEkle(j, i, "yuru", nil, sure, { tur = "YURU" })
    end

    -- Başlangıç kenarı: oyuncunun bulunduğu yerde kendine dönen kenar
    local baslangic = graf:kenarEkle(1, 1, "basla", nil, 0, { tur = "BASLA" })

    -- Durak kenarları (gerekli kenarlar)
    for i, n in ipairs(noktalar) do
        if n.tur == "DURAK" then
            graf:kenarEkle(i, i, "durak", nil, 0, { tur = "DURAK", durak = n.durak, konum = n.konum })
        end
    end

    -- 1) Yürüme: her düğümü en yakın K komşusuna bağla
    for i = 1, #noktalar do
        local digerleri = {}
        for j = 1, #noktalar do
            if j ~= i then
                table.insert(digerleri, j)
            end
        end
        table.sort(digerleri, function(a, b)
            local ma, mb = sureBul(i, a, 1), sureBul(i, b, 1)
            if ma ~= mb then
                return ma < mb
            end
            return a < b   -- eşit uzaklıkta sıra hep aynı olsun
        end)
        for n = 1, math.min(self.ayar.komsuSayisi, #digerleri) do
            local j = digerleri[n]
            if sureBul(i, j, 1) <= self.ayar.komsuMesafesi then
                yurumeEkle(i, j)
            end
        end
    end

    -- 2) Uçuş: bilinen uçuş noktaları arasında
    for i = ilkUcus, #noktalar do
        for j = ilkUcus, #noktalar do
            if i ~= j then
                local sure = sureBul(i, j, self.ayar.ucusHizi) + self.ayar.ucusBekleme
                graf:kenarEkle(i, j, "uc", nil, sure, {
                    tur = "UCUS",
                    nereden = noktalar[i].ad,
                    nereye = noktalar[j].ad,
                    konum = noktalar[i].konum,   -- uçuş ustasının yeri (yön oku buraya)
                })
                birlestir(i, j)
            end
        end
    end

    -- 3) Köprü: kopuk parça kaldıysa en kısa yürüme kenarlarıyla birleştir (Kruskal).
    --    Bütün düğüm çiftlerini kısadan uzuna sırala; iki ayrı parçayı bağlayan kenarı ekle.
    local ciftler = {}
    for i = 1, #noktalar do
        for j = i + 1, #noktalar do
            table.insert(ciftler, { i = i, j = j, m = sureBul(i, j, 1) })
        end
    end
    table.sort(ciftler, function(a, b)
        if a.m ~= b.m then
            return a.m < b.m
        end
        if a.i ~= b.i then
            return a.i < b.i
        end
        return a.j < b.j
    end)
    for _, c in ipairs(ciftler) do
        if kok(c.i) ~= kok(c.j) then
            yurumeEkle(c.i, c.j)
        end
    end

    -- 4) Her düğümden çıkan kenarları kısadan uzuna sırala.
    --    ATLAS'ın DFS'i komşuları bu sırayla gezdiği için önce yakın yerlere iner.
    for _, liste in pairs(graf.dugumler) do
        table.sort(liste, function(a, b)
            local ka, kb = graf:kenar(a).agirlik, graf:kenar(b).agirlik
            if ka ~= kb then
                return ka < kb
            end
            return a < b
        end)
    end

    return graf, baslangic, ulasilamaz
end

-- Ana iş: durakları sıraya koyar.
-- oyuncu       : { kita, x, y, ... }
-- duraklar     : ns.DurakOlustur ile oluşturulmuş duraklar
-- ucusNoktalari: { { ad, konum }, ... }
-- Dönüş: { adimlar = { {tur, durak|ad, konum, sure}, ... }, toplamSure, ulasilamaz = {...} }
function Planlayici:planla(oyuncu, duraklar, ucusNoktalari)
    local graf, baslangic, ulasilamaz = self:grafKur(oyuncu, duraklar, ucusNoktalari)
    local onk = onkosullariBul(duraklar)

    local yol = {}               -- bütün turların birleşik yolu
    local turBaslangici = baslangic

    for _, odul in ipairs(ODUL_KADEMELERI) do
        -- Değer fonksiyonu. ATLAS her iterasyonda yeni bir 'yoldakiler' tablosu verir;
        -- o ana kadar tamamlanan durakları bir kez hesaplayıp saklıyoruz (önbellek).
        local onbellekAnahtar, onbellekBitti = nil, nil
        local function deger(etiket, yoldakiler, g, atlasYolu)
            if onbellekAnahtar ~= yoldakiler then
                onbellekAnahtar = yoldakiler
                onbellekBitti = tamamlananlariBul(g, yol, onk, atlasYolu)
            end
            local kenar = g:kenar(etiket)
            local d = kenar.veri.durak
            if d and not onbellekBitti[d] and hepsiBitti(onk[d], onbellekBitti) then
                return odul - kenar.agirlik
            end
            return -kenar.agirlik
        end

        local turYolu = self.cozucu:coz(graf, turBaslangici, deger)
        -- turYolu[1] her zaman turun başlangıç kenarıdır; o zaten yolda (ilk tur hariç)
        for i, etiket in ipairs(turYolu) do
            if i > 1 or #yol == 0 then
                table.insert(yol, etiket)
            end
        end
        turBaslangici = yol[#yol]
    end

    local bitti, sira = tamamlananlariBul(graf, yol, onk)

    -- Yolu oyuncuya gösterilecek adımlara çevir.
    -- Her adımın 'sure' alanı: bir önceki adımdan bu adıma gelme süresi.
    local adimlar = {}
    local biriken = 0
    for i, etiket in ipairs(yol) do
        local kenar = graf:kenar(etiket)
        if sira[i] then
            table.insert(adimlar, { tur = sira[i].tur, durak = sira[i], konum = sira[i].konum, sure = biriken })
            biriken = 0
        elseif kenar.veri.tur == "UCUS" then
            table.insert(adimlar, {
                tur = "UCUS",
                ad = kenar.veri.nereden .. " -> " .. kenar.veri.nereye,
                konum = kenar.veri.konum,
                sure = biriken,
            })
            biriken = kenar.agirlik
        else
            biriken = biriken + kenar.agirlik
        end
    end
    -- Son duraktan sonra kalan uçuşlar gereksiz: at
    while #adimlar > 0 and adimlar[#adimlar].tur == "UCUS" do
        table.remove(adimlar)
    end

    local toplam = 0
    for _, a in ipairs(adimlar) do
        toplam = toplam + a.sure
    end

    -- Kıtada olduğu hâlde tamamlanamayanlar (ör. önkoşulu başka kıtada) da ulaşılamaz sayılır
    local zatenListede = {}
    for _, d in ipairs(ulasilamaz) do
        zatenListede[d] = true
    end
    for _, d in ipairs(duraklar) do
        if not bitti[d] and not zatenListede[d] then
            table.insert(ulasilamaz, d)
        end
    end

    return { adimlar = adimlar, toplamSure = toplam, ulasilamaz = ulasilamaz, cozucu = self.cozucu.ad }
end

ns.Planlayici = Planlayici
