-- oyun/olay_yayincisi.lua
-- OBSERVER deseni: oyunun olaylarını (QUEST_ACCEPTED, QUEST_LOG_UPDATE ...) dağıtır.
--   Yayıncı  : OlayYayincisi — oyundan olayı alan tek bir görünmez çerçeve
--   Aboneler : aboneOl(olay, fonksiyon) ile kaydolan fonksiyonlar
-- Yeni bir tepki eklemek için yayıncıyı değiştirmeye gerek yok; yeni abone eklenir (OCP).

local _, ns = ...

local OlayYayincisi = {}
OlayYayincisi.__index = OlayYayincisi

-- cerceveOlustur: görünmez bir oyun çerçevesi döndüren fonksiyon (oyunda CreateFrame)
function OlayYayincisi.yeni(cerceveOlustur)
    local y = setmetatable({}, OlayYayincisi)
    y.aboneler = {}   -- olay adı -> fonksiyon listesi
    y.cerceve = cerceveOlustur()
    y.cerceve:SetScript("OnEvent", function(_, olay, ...)
        y:bildir(olay, ...)
    end)
    return y
end

function OlayYayincisi:aboneOl(olay, fonksiyon)
    if not self.aboneler[olay] then
        self.aboneler[olay] = {}
        self.cerceve:RegisterEvent(olay)   -- oyuna "bu olayı bana haber ver" de
    end
    table.insert(self.aboneler[olay], fonksiyon)
end

-- Olay gelince o olaya abone olan herkese haber ver
function OlayYayincisi:bildir(olay, ...)
    for _, fonksiyon in ipairs(self.aboneler[olay] or {}) do
        fonksiyon(...)
    end
end

ns.OlayYayincisi = OlayYayincisi
