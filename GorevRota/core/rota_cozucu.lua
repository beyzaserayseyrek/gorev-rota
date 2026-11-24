-- core/rota_cozucu.lua
-- STRATEGY deseni.
--   RotaCozucu : "arayüz" — her rota çözücü  ad  alanı ve  coz(...)  yöntemi sağlamalı.
--   AtlasCozucu: tek somut strateji — hocanın ATLAS algoritması.
-- Planlayıcı yalnızca arayüzü bilir; hangi algoritmanın çalıştığını bilmez (DIP).

local _, ns = ...

local RotaCozucu = {}

-- Lua'da "interface" anahtar sözcüğü yok; bu yüzden gerekli alanları kontrol ediyoruz.
function RotaCozucu.dogrula(cozucu)
    assert(type(cozucu) == "table", "RotaCozucu bir tablo olmalı")
    assert(type(cozucu.ad) == "string", "RotaCozucu bir 'ad' alanı içermeli")
    assert(type(cozucu.coz) == "function", "RotaCozucu bir 'coz' yöntemi içermeli")
    return cozucu
end

ns.RotaCozucu = RotaCozucu

-- coz(graf, baslangicKenari, degerFn) -> kenar etiketleri dizisi (yürünecek sıra)
local AtlasCozucu = { ad = "ATLAS" }

function AtlasCozucu:coz(graf, baslangicKenari, degerFn)
    local yol, sonKenar = ns.Atlas.enUzunYol(graf, baslangicKenari, degerFn)
    -- Java sürümü son kenarı listeden düşürerek döner. Planlamada son durağı
    -- kaybetmemek için o kenarı geri ekliyoruz.
    table.insert(yol, sonKenar)
    return yol
end

ns.AtlasCozucu = RotaCozucu.dogrula(AtlasCozucu)
