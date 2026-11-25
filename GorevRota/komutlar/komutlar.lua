-- komutlar/komutlar.lua
-- COMMAND deseni: her /gr komutu ayrı bir nesnedir.
--   Komut          : { ad, takmaAdlar, calistir(self, cephe, argumanlar) }
--   KomutIsleyici  : yazılan metni çözer, doğru komutu bulup çalıştırır (çağıran)
--   Cephe          : işi asıl yapan alıcı (GorevRotaCephesi)
-- Yeni komut eklemek = yeni bir tablo yazıp kaydetmek; işleyici değişmez (OCP).

local _, ns = ...

-- ---------- Komut işleyici ----------
local KomutIsleyici = {}
KomutIsleyici.__index = KomutIsleyici

function KomutIsleyici.yeni(cephe)
    return setmetatable({ cephe = cephe, komutlar = {}, sirali = {} }, KomutIsleyici)
end

function KomutIsleyici:kaydet(komut)
    self.komutlar[komut.ad] = komut
    for _, takma in ipairs(komut.takmaAdlar or {}) do
        self.komutlar[takma] = komut
    end
    table.insert(self.sirali, komut)
end

-- "/gr ekle hedef 45 60 Kurt" -> metin = "ekle hedef 45 60 Kurt"
function KomutIsleyici:isle(metin)
    local ad, argumanlar = (metin or ""):match("^%s*(%S*)%s*(.-)%s*$")
    ad = (ad or ""):lower()
    if ad == "" then
        ad = "yardim"
    end
    local komut = self.komutlar[ad]
    if not komut then
        self.cephe:yaz("Bilinmeyen komut: " .. ad)
        komut = self.komutlar.yardim
    end
    komut:calistir(self.cephe, argumanlar or "")
end

ns.KomutIsleyici = KomutIsleyici

-- ---------- Komutlar ----------
local Komutlar = {}

Komutlar.Plan = {
    ad = "plan",
    calistir = function(self, cephe)
        cephe:planla(false)
    end,
}

Komutlar.Liste = {
    ad = "liste",
    takmaAdlar = { "list" },
    calistir = function(self, cephe)
        cephe:listeYaz()
    end,
}

Komutlar.Panel = {
    ad = "panel",
    calistir = function(self, cephe)
        cephe:paneliAcKapa()
    end,
}

local TURLER = { al = "AL", hedef = "HEDEF", teslim = "TESLIM" }

Komutlar.Ekle = {
    ad = "ekle",
    takmaAdlar = { "add" },
    -- Biçim: <al|hedef|teslim> [x y] <ad>     (x, y: haritadaki koordinat, 0..100)
    calistir = function(self, cephe, argumanlar)
        local turKelimesi, kalan = argumanlar:match("^(%S+)%s*(.-)$")
        local tur = turKelimesi and TURLER[turKelimesi:lower()]
        if not tur then
            cephe:yaz("Kullanım: /gr ekle <al|hedef|teslim> [x y] <ad>")
            return
        end
        local x, y, ad = kalan:match("^(%d+%.?%d*)%s+(%d+%.?%d*)%s*(.*)$")
        local hx, hy = nil, nil
        if x then
            hx, hy = tonumber(x) / 100, tonumber(y) / 100
        else
            ad = kalan
        end
        if ad == "" then
            ad = "Durak"
        end
        cephe:durakEkle(tur, ad, hx, hy)
    end,
}

Komutlar.Tamam = {
    ad = "tamam",
    takmaAdlar = { "done" },
    calistir = function(self, cephe)
        cephe:ilkDuragiTamamla()
    end,
}

Komutlar.Temizle = {
    ad = "temizle",
    takmaAdlar = { "clear" },
    calistir = function(self, cephe)
        cephe:elleDuraklariTemizle()
    end,
}

Komutlar.Yardim = {
    ad = "yardim",
    takmaAdlar = { "help", "yardım" },
    calistir = function(self, cephe)
        for _, satir in ipairs(ns.Metin.YARDIM) do
            cephe:yaz(satir)
        end
    end,
}

-- Bütün komutları bir işleyiciye kaydeder
function Komutlar.hepsiniKaydet(isleyici)
    for _, k in ipairs({ Komutlar.Plan, Komutlar.Liste, Komutlar.Panel, Komutlar.Ekle,
                         Komutlar.Tamam, Komutlar.Temizle, Komutlar.Yardim }) do
        isleyici:kaydet(k)
    end
end

ns.Komutlar = Komutlar
