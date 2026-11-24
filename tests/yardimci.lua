-- tests/yardimci.lua
-- Küçük test yardımcıları. Testler repo kökünden çalıştırılır:  luajit tests/hepsi.lua

if _G.GR_TEST then
    return _G.GR_TEST   -- birden çok test dosyası aynı sayaçları paylaşsın
end

local T = { gecen = 0, kalan = 0 }

-- WoW her eklenti dosyasını ("GorevRota", ns) argümanlarıyla çalıştırır.
-- Aynısını burada yapıyoruz; böylece dosyalar hiç değişmeden oyun dışında da çalışır.
function T.yukle(dosyalar)
    local ns = {}
    for _, dosya in ipairs(dosyalar) do
        local parca, hata = loadfile(dosya)
        assert(parca, hata)
        parca("GorevRota", ns)
    end
    return ns
end

-- Çekirdek dosyaları (.toc'taki sırayla)
T.CEKIRDEK = {
    "GorevRota/core/graf.lua",
    "GorevRota/core/atlas.lua",
    "GorevRota/core/rota_cozucu.lua",
    "GorevRota/core/gorev_modeli.lua",
    "GorevRota/core/planlayici.lua",
}

function T.baslik(metin)
    print("")
    print("== " .. metin)
end

function T.esit(gelen, beklenen, mesaj)
    if gelen == beklenen then
        T.gecen = T.gecen + 1
        print("  [TAMAM] " .. mesaj)
    else
        T.kalan = T.kalan + 1
        print("  [HATA]  " .. mesaj)
        print("          beklenen: " .. tostring(beklenen))
        print("          gelen   : " .. tostring(gelen))
    end
end

function T.dogru(kosul, mesaj)
    T.esit(kosul and true or false, true, mesaj)
end

function T.ozet()
    print("")
    print(string.format("Sonuç: %d test geçti, %d test kaldı.", T.gecen, T.kalan))
    if T.kalan > 0 then
        os.exit(1)
    end
end

-- Dosyayı satır satır okur
function T.satirlar(dosya)
    local liste = {}
    for satir in io.lines(dosya) do
        table.insert(liste, satir)
    end
    return liste
end

_G.GR_TEST = T
return T
