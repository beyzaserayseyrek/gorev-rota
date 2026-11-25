-- oyun/wow_gorev_adaptoru.lua
-- ADAPTER deseni: oyunun API'sini (C_QuestLog, C_Map, C_TaxiMap ...) bizim
-- görev modelimize (ns.DurakOlustur ile oluşturulan duraklar) çevirir.
--
-- Planlayıcı ve ATLAS oyunu hiç bilmez; oyun API'si değişirse yalnızca bu dosya değişir.
-- Oyun fonksiyonları 'api' tablosuyla dışarıdan verilir (DIP). Böylece testlerde
-- sahte bir api verip bu dosyayı oyun olmadan sınayabiliriz.

local _, ns = ...

local WowGorevAdaptoru = {}
WowGorevAdaptoru.__index = WowGorevAdaptoru

-- api: { C_QuestLog, C_Map, C_TaxiMap, GetQuestUiMapID, GetTaxiMapID, CreateVector2D, Enum }
function WowGorevAdaptoru.yeni(api)
    local a = setmetatable({}, WowGorevAdaptoru)
    a.api = api
    return a
end

-- Harita konumunu (harita no + 0..1 arası x, y) kıta konumuna (yard) çevirir.
-- Çevrilemezse (ör. zindan içi) nil döner.
function WowGorevAdaptoru:haritaKonumunuCevir(harita, hx, hy)
    if not harita or not hx or not hy then
        return nil
    end
    local kita, dunya = self.api.C_Map.GetWorldPosFromMapPos(harita, self.api.CreateVector2D(hx, hy))
    if not kita or not dunya then
        return nil
    end
    local x, y = dunya:GetXY()
    return { kita = kita, x = x, y = y, harita = harita, hx = hx, hy = hy }
end

-- Oyuncunun şu anki konumu (bilinmiyorsa nil)
function WowGorevAdaptoru:oyuncuKonumu()
    local harita = self.api.C_Map.GetBestMapForUnit("player")
    if not harita then
        return nil
    end
    local konum = self.api.C_Map.GetPlayerMapPosition(harita, "player")
    if not konum then
        return nil
    end
    local hx, hy = konum:GetXY()
    return self:haritaKonumunuCevir(harita, hx, hy)
end

-- Bir görevin haritadaki işaretinin konumu.
-- Oyun, görev bitmemişse hedef bölgesini, bitmişse teslim yerini gösterir.
function WowGorevAdaptoru:gorevKonumu(gorevId, haritaOnbellegi)
    local harita = self.api.GetQuestUiMapID and self.api.GetQuestUiMapID(gorevId)
    if not harita or harita == 0 then
        return nil
    end
    -- Aynı haritayı tekrar tekrar sormamak için önbellek
    if not haritaOnbellegi[harita] then
        haritaOnbellegi[harita] = self.api.C_QuestLog.GetQuestsOnMap(harita) or {}
    end
    for _, isaret in ipairs(haritaOnbellegi[harita]) do
        if isaret.questID == gorevId then
            return self:haritaKonumunuCevir(harita, isaret.x, isaret.y)
        end
    end
    return nil
end

-- Görev kütüğünü okuyup durak listesi üretir.
-- teslimYerleri: { [gorevId] = konum } — görev alınırken kaydedilen yerler (görevi verenin yanı)
function WowGorevAdaptoru:duraklariOku(teslimYerleri)
    local Q = self.api.C_QuestLog
    local duraklar = {}
    local haritaOnbellegi = {}

    for i = 1, Q.GetNumQuestLogEntries() do
        local bilgi = Q.GetInfo(i)
        -- Başlık satırlarını ve gizli görevleri atla
        if bilgi and not bilgi.isHeader and not bilgi.isHidden and bilgi.questID and bilgi.questID > 0 then
            local id = bilgi.questID
            local isaret = self:gorevKonumu(id, haritaOnbellegi)
            if Q.IsComplete(id) then
                -- Bitti: sadece teslim kaldı
                table.insert(duraklar, ns.DurakOlustur({
                    gorevId = id, gorevAdi = bilgi.title, tur = ns.DurakTuru.TESLIM,
                    konum = isaret or teslimYerleri[id],
                }))
            else
                -- Bitmedi: önce hedef, teslim yerini biliyorsak sonra teslim
                table.insert(duraklar, ns.DurakOlustur({
                    gorevId = id, gorevAdi = bilgi.title, tur = ns.DurakTuru.HEDEF, konum = isaret,
                }))
                if teslimYerleri[id] then
                    table.insert(duraklar, ns.DurakOlustur({
                        gorevId = id, gorevAdi = bilgi.title, tur = ns.DurakTuru.TESLIM,
                        konum = teslimYerleri[id],
                    }))
                end
            end
        end
    end
    return duraklar
end

-- Uçuş haritası açıkken bilinen uçuş noktalarını okur.
-- Dönüş: { { id, ad, konum }, ... }
function WowGorevAdaptoru:ucusNoktalariniOku()
    local api = self.api
    if not api.C_TaxiMap or not api.GetTaxiMapID then
        return {}
    end
    local harita = api.GetTaxiMapID()
    if not harita then
        return {}
    end
    -- Enum yoksa oyunun sayısal değeri: 2 = ulaşılamaz
    local ULASILAMAZ = (api.Enum and api.Enum.FlightPathState and api.Enum.FlightPathState.Unreachable) or 2
    local liste = {}
    for _, nokta in ipairs(api.C_TaxiMap.GetAllTaxiNodes(harita) or {}) do
        if nokta.state ~= ULASILAMAZ and nokta.position then
            local hx, hy = nokta.position:GetXY()
            local konum = self:haritaKonumunuCevir(harita, hx, hy)
            if konum then
                table.insert(liste, { id = nokta.nodeID, ad = nokta.name, konum = konum })
            end
        end
    end
    return liste
end

ns.WowGorevAdaptoru = WowGorevAdaptoru
