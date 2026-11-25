-- tests/sahte_wow.lua
-- Oyun olmadan test edebilmek için WoW API'sinin küçük bir taklidi.
-- Fonksiyon adları ve dönüş biçimleri gerçek oyundakiyle aynıdır; içleri basit tablolardır.
--
-- Sahte dünya:
--   Harita 1 (Elwynn gibi)   : kıta 0 üzerinde, 1000 x 1000 yard, sol üst köşe (0, 0)
--   Harita 2 (komşu bölge)   : kıta 0 üzerinde, 1000 x 1000 yard, sol üst köşe (1000, 0)
--   Harita 3 (başka kıta)    : kıta 1

local S = {}

-- ---------- Vektör (oyundaki CreateVector2D) ----------
local function vektor(x, y)
    return { x = x, y = y, GetXY = function(self) return self.x, self.y end }
end

-- ---------- Sahte dünya verisi (testler değiştirebilir) ----------
function S.sifirla()
    S.oyuncu = { harita = 1, hx = 0.10, hy = 0.10 }
    S.gorevler = {
        { title = "Elwynn", isHeader = true },
        { title = "Kurt Avı", questID = 101, tamam = false, harita = 1, x = 0.40, y = 0.10 },
        { title = "Mektup", questID = 102, tamam = true, harita = 1, x = 0.20, y = 0.30 },
        { title = "Uzak Diyar", questID = 103, tamam = false, harita = 3, x = 0.50, y = 0.50 },
        { title = "Gizli", questID = 104, isHidden = true },
    }
    S.ucusNoktalari = {
        { nodeID = 1, name = "Goldshire", state = 1, position = vektor(0.12, 0.12) },
        { nodeID = 2, name = "Doğu Kampı", state = 1, position = vektor(0.90, 0.10) },
        { nodeID = 3, name = "Bilinmeyen", state = 2, position = vektor(0.50, 0.90) },
    }
    S.mesajlar = {}
    S.yerIsareti = nil
    S.takipGorevi = nil
    S.cerceveler = {}
    S.zamanlayicilar = {}
end

-- ---------- Oyun API'si ----------
function S.api()
    local api = {}

    api.CreateVector2D = vektor

    api.C_Map = {
        GetBestMapForUnit = function(birim)
            return S.oyuncu and S.oyuncu.harita
        end,
        GetPlayerMapPosition = function(harita, birim)
            if not S.oyuncu or S.oyuncu.harita ~= harita then
                return nil
            end
            return vektor(S.oyuncu.hx, S.oyuncu.hy)
        end,
        GetWorldPosFromMapPos = function(harita, v)
            if harita == 1 then
                return 0, vektor(v.x * 1000, v.y * 1000)
            elseif harita == 2 then
                return 0, vektor(1000 + v.x * 1000, v.y * 1000)
            elseif harita == 3 then
                return 1, vektor(v.x * 1000, v.y * 1000)
            end
            return nil
        end,
        CanSetUserWaypointOnMap = function(harita)
            return harita == 1 or harita == 2 or harita == 3
        end,
        SetUserWaypoint = function(nokta)
            S.yerIsareti = nokta
        end,
        ClearUserWaypoint = function()
            S.yerIsareti = nil
        end,
    }

    api.C_QuestLog = {
        GetNumQuestLogEntries = function()
            return #S.gorevler
        end,
        GetInfo = function(i)
            return S.gorevler[i]
        end,
        IsComplete = function(id)
            for _, g in ipairs(S.gorevler) do
                if g.questID == id then
                    return g.tamam
                end
            end
            return false
        end,
        GetQuestsOnMap = function(harita)
            local liste = {}
            for _, g in ipairs(S.gorevler) do
                if g.harita == harita then
                    table.insert(liste, { questID = g.questID, x = g.x, y = g.y })
                end
            end
            return liste
        end,
    }

    api.GetQuestUiMapID = function(id)
        for _, g in ipairs(S.gorevler) do
            if g.questID == id then
                return g.harita or 0
            end
        end
        return 0
    end

    api.C_TaxiMap = {
        GetAllTaxiNodes = function(harita)
            return S.ucusNoktalari
        end,
    }
    api.GetTaxiMapID = function()
        return 1
    end
    api.Enum = { FlightPathState = { Current = 0, Reachable = 1, Unreachable = 2 } }

    api.C_SuperTrack = {
        SetSuperTrackedUserWaypoint = function(acik)
            S.takipGorevi = acik and "yer-isareti" or nil
        end,
        SetSuperTrackedQuestID = function(id)
            S.takipGorevi = id
        end,
    }
    api.UiMapPoint = {
        CreateFromCoordinates = function(harita, x, y)
            return { uiMapID = harita, position = vektor(x, y) }
        end,
    }

    return api
end

-- ---------- Arayüz (CreateFrame) taklidi ----------
-- Bilinmeyen her yöntem "hiçbir şey yapma" olarak davranır; önemli olanlar durum tutar.
local Cerceve = {}
Cerceve.__index = function(tablo, anahtar)
    if Cerceve[anahtar] then
        return Cerceve[anahtar]
    end
    return function() end
end

local function yeniCerceve(tur)
    local c = setmetatable({ tur = tur, gorunur = true, betikler = {}, olaylar = {}, metin = "" }, Cerceve)
    table.insert(S.cerceveler, c)
    return c
end

function Cerceve:SetScript(ad, fn) self.betikler[ad] = fn end
function Cerceve:GetScript(ad) return self.betikler[ad] end
function Cerceve:RegisterEvent(olay) self.olaylar[olay] = true end
function Cerceve:UnregisterEvent(olay) self.olaylar[olay] = nil end
function Cerceve:Show() self.gorunur = true end
function Cerceve:Hide() self.gorunur = false end
function Cerceve:IsShown() return self.gorunur end
function Cerceve:SetText(m) self.metin = m end
function Cerceve:GetText() return self.metin end
function Cerceve:CreateFontString() return yeniCerceve("FontString") end
function Cerceve:CreateTexture() return yeniCerceve("Texture") end

-- Oyunun global ortamını kurar (eklentinin tüm dosyaları yüklenmeden önce)
function S.globalleriKur()
    for ad, deger in pairs(S.api()) do
        _G[ad] = deger
    end
    _G.UIParent = yeniCerceve("Frame")
    _G.CreateFrame = function(tur) return yeniCerceve(tur) end
    _G.SlashCmdList = {}
    _G.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, m) table.insert(S.mesajlar, m) end,
    }
    _G.C_Timer = {
        After = function(saniye, fn) table.insert(S.zamanlayicilar, fn) end,
    }
end

-- Bekleyen zamanlayıcıları çalıştırır (oyunda zaman geçmiş gibi)
function S.zamanGecir()
    local liste = S.zamanlayicilar
    S.zamanlayicilar = {}
    for _, fn in ipairs(liste) do
        fn()
    end
end

-- Oyun bir olay yayınlamış gibi davranır
function S.olayAtesle(olay, ...)
    for _, c in ipairs(S.cerceveler) do
        if c.olaylar[olay] and c.betikler.OnEvent then
            c.betikler.OnEvent(c, olay, ...)
        end
    end
end

-- Sohbet penceresine yazılanlardan aranan metni içeren var mı?
function S.mesajVarMi(parca)
    for _, m in ipairs(S.mesajlar) do
        if m:find(parca, 1, true) then
            return true
        end
    end
    return false
end

S.sifirla()
return S
