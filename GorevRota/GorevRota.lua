-- GorevRota.lua
-- Giriş noktası: parçaları oluşturup birbirine bağlar. (.toc'ta en son yüklenir.)
-- Oyunun global fonksiyonlarına yalnızca bu dosya dokunur; diğer dosyalara
-- ihtiyaç duydukları şeyler parametre olarak verilir.

local eklentiAdi, ns = ...

local yayinci = ns.OlayYayincisi.yeni(function()
    return CreateFrame("Frame")
end)

-- Oyun fonksiyonlarını tek tabloda topla (adaptöre ve yön okuna verilecek)
local function oyunApisi()
    return {
        C_QuestLog = C_QuestLog,
        C_Map = C_Map,
        C_TaxiMap = C_TaxiMap,
        C_SuperTrack = C_SuperTrack,
        GetQuestUiMapID = GetQuestUiMapID,
        GetTaxiMapID = GetTaxiMapID,
        CreateVector2D = CreateVector2D,
        UiMapPoint = UiMapPoint,
        Enum = Enum,
    }
end

local function kur()
    -- Kayıtlı veri (.toc'taki SavedVariables): oyundan çıkınca da saklanır
    GorevRotaDB = GorevRotaDB or {}

    local api = oyunApisi()
    local cephe = ns.GorevRotaCephesi.yeni({
        adaptor = ns.WowGorevAdaptoru.yeni(api),
        planlayici = ns.Planlayici.yeni(ns.AtlasCozucu),   -- Strategy: ATLAS
        panel = ns.ListePaneli.yeni({ CreateFrame = CreateFrame, UIParent = UIParent }),
        yonOku = ns.YonOku.yeni(api),
        db = GorevRotaDB,
        yazdir = function(metin)
            DEFAULT_CHAT_FRAME:AddMessage(metin)
        end,
        zamanla = function(saniye, fonksiyon)
            C_Timer.After(saniye, fonksiyon)
        end,
    })
    ns.cephe = cephe

    -- Command: /gr ve /gorevrota komutları
    local isleyici = ns.KomutIsleyici.yeni(cephe)
    ns.Komutlar.hepsiniKaydet(isleyici)
    SLASH_GOREVROTA1 = "/gr"
    SLASH_GOREVROTA2 = "/gorevrota"
    SlashCmdList["GOREVROTA"] = function(metin)
        isleyici:isle(metin)
    end

    -- Observer: oyun olaylarına abone ol
    -- QUEST_ACCEPTED eski sürümlerde (indeks, görevId), yenilerde (görevId) gönderir
    yayinci:aboneOl("QUEST_ACCEPTED", function(a, b)
        cephe:gorevAlindi(b or a)
    end)
    yayinci:aboneOl("QUEST_TURNED_IN", function(gorevId)
        cephe:gorevBitti(gorevId)
    end)
    yayinci:aboneOl("QUEST_REMOVED", function(gorevId)
        cephe:gorevBitti(gorevId)
    end)
    yayinci:aboneOl("QUEST_LOG_UPDATE", function()
        cephe:gecikmeliPlanla()
    end)
    yayinci:aboneOl("ZONE_CHANGED_NEW_AREA", function()
        cephe:gecikmeliPlanla()
    end)
    yayinci:aboneOl("TAXIMAP_OPENED", function()
        cephe:ucusNoktalariniKaydet()
    end)

    cephe:yaz("yüklendi. Komutlar için /gr yardim")
end

-- Eklentinin kayıtlı verisi ADDON_LOADED olayında hazır olur
yayinci:aboneOl("ADDON_LOADED", function(ad)
    if ad == eklentiAdi then
        kur()
    end
end)
