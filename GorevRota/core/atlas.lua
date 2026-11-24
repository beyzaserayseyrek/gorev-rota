-- core/atlas.lua
-- ATLAS algoritması: hocanın Atlas.java dosyasının satır satır Lua 5.1 çevirisi.
-- Kaynak: https://github.com/savastakan/atlas
--
-- Fikir: Graftaki kenarları tek bir yürüyüşte dolaşmak.
--   1) Yolun son kenarından DFS yap, kenarları "bitiş sırasına" göre yığına koy.
--   2) Yığından çekerek dinamik programlama ile "en çok yeni kenar toplayan" zinciri bul.
--   3) Zinciri yola ekle; yeni kenar kazandıran zincir kalmayınca dur.
--
-- Tek bir ekleme yaptık: kenarın "değeri" dışarıdan verilebilir (degerFn).
-- Verilmezse Java'daki gibi: yolda olmayan kenar 1, yolda olan kenar 0 değerindedir.

local _, ns = ...

local Atlas = {}

-- Java'daki Integer.MIN_VALUE yerine eksi sonsuz kullanıyoruz.
local EKSI_SONSUZ = -math.huge

-- Java: dfs(graph, edge, cost, stack)
-- maliyet[e] = EKSI_SONSUZ  "bu kenar görüldü" anlamına gelir.
local function dfs(graf, kenar, maliyet, yigin)
    maliyet[kenar.etiket] = EKSI_SONSUZ
    for _, komsu in ipairs(graf:cikanKenarlar(kenar.hedef)) do
        if maliyet[komsu] ~= EKSI_SONSUZ then
            dfs(graf, graf:kenar(komsu), maliyet, yigin)
        end
    end
    table.insert(yigin, kenar)   -- Java: stack.add(edge)
end

-- Java'daki varsayılan değer:  path.contains(e) ? 0 : 1
local function varsayilanDeger(etiket, yoldakiler)
    if yoldakiler[etiket] then
        return 0
    end
    return 1
end

-- Java: longestPath(graph, start)
-- Dönüş: yol (kenar etiketleri dizisi) ve son adımda yoldan çıkarılan kenar.
-- (Java da o kenarı çıkarıp geri eklemeden döner; test için aynısını yapıyoruz.)
function Atlas.enUzunYol(graf, baslangic, degerFn)
    degerFn = degerFn or varsayilanDeger
    local yol = { baslangic }

    while true do
        local suankiBaslangic = table.remove(yol)   -- Java: path.removeLast()

        -- path.contains() hızlı olsun diye yoldaki kenarların kümesi
        local yoldakiler = {}
        for _, e in ipairs(yol) do
            yoldakiler[e] = true
        end

        local yigin = {}
        local maliyet = {}
        local ziyaret = {}
        local enIyiMaliyet = EKSI_SONSUZ   -- Java: currentCost
        local enIyi = nil                  -- Java: current

        dfs(graf, graf:kenar(suankiBaslangic), maliyet, yigin)
        local nereden = {}                 -- Java: comeFrom (nil = zincirin başı)
        maliyet[suankiBaslangic] = 0

        -- Dinamik programlama: yığının tepesinden başlayarak maliyetleri büyüt
        while #yigin > 0 do
            local kenar = table.remove(yigin)   -- Java: stack.pop()
            ziyaret[kenar.etiket] = true
            for _, komsu in ipairs(graf:cikanKenarlar(kenar.hedef)) do
                if not ziyaret[komsu] then
                    local yeniMaliyet = maliyet[kenar.etiket] + degerFn(komsu, yoldakiler, graf, yol)
                    if maliyet[komsu] < yeniMaliyet then
                        maliyet[komsu] = yeniMaliyet
                        nereden[komsu] = kenar.etiket
                        if enIyiMaliyet < maliyet[komsu] then
                            enIyiMaliyet = maliyet[komsu]
                            enIyi = komsu
                        end
                    end
                end
            end
        end

        -- Kazandıran zincir yoksa bitir. (enIyi == nil: Java'da bu durumda dizi hatası olurdu)
        if enIyi == nil or maliyet[enIyi] <= 0 then
            return yol, suankiBaslangic
        end

        -- Zinciri sondan başa izleyip yolun sonuna ekle (Java: path.add(size, current))
        local boyut = #yol
        local e = enIyi
        table.insert(yol, e)
        while nereden[e] ~= nil do
            e = nereden[e]
            table.insert(yol, boyut + 1, e)
        end
    end
end

-- Java: getTestSuite(graph, path) — yoldaki kenarların girdilerini virgülle birleştirir.
function Atlas.testDizisi(graf, yol)
    local parcalar = {}
    for _, etiket in ipairs(yol) do
        table.insert(parcalar, tostring(graf:kenar(etiket).girdi))
    end
    return table.concat(parcalar, ",")
end

-- Java: printPath(graph, path) — "kaynak_hedef_girdi , " biçiminde.
function Atlas.yolMetni(graf, yol)
    local parcalar = {}
    for _, etiket in ipairs(yol) do
        local k = graf:kenar(etiket)
        table.insert(parcalar, k.kaynak .. "_" .. k.hedef .. "_" .. tostring(k.girdi) .. " , ")
    end
    return table.concat(parcalar)
end

-- Java: run(graph) — ilk başlangıç kenarından çalıştırır.
function Atlas.calistir(graf)
    local yol = Atlas.enUzunYol(graf, graf.baslangiclar[1])
    return Atlas.testDizisi(graf, yol)
end

ns.Atlas = Atlas
