-- arayuz/liste_paneli.lua
-- Oyun içi panel: sıralı durakları oklarla, alt alta gösterir.
-- Panel yalnızca bir "plan" alır ve çizer; planın nasıl hesaplandığını bilmez (SRP).

local _, ns = ...

local ListePaneli = {}
ListePaneli.__index = ListePaneli

local SATIR_SAYISI = 12
local SATIR_YUKSEKLIGI = 18
-- Satır başındaki ok: oyunun kendi "sonraki sayfa" düğmesi resmi
local OK = "|TInterface\\Buttons\\UI-SpellbookIcon-NextPage-Up:16:16|t"

-- ui: { CreateFrame, UIParent }
function ListePaneli.yeni(ui)
    return setmetatable({ ui = ui, satirlar = {} }, ListePaneli)
end

-- Çerçeveyi ilk gerektiğinde bir kez oluşturur
function ListePaneli:olustur()
    if self.cerceve then
        return
    end
    local ui = self.ui
    local f = ui.CreateFrame("Frame", "GorevRotaPaneli", ui.UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(360, 70 + SATIR_SAYISI * SATIR_YUKSEKLIGI)
    f:SetPoint("RIGHT", ui.UIParent, "RIGHT", -60, 0)
    f:SetClampedToScreen(true)
    -- Fareyle sürüklenebilsin
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local baslik = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    baslik:SetPoint("TOP", f, "TOP", 0, -6)
    baslik:SetText(ns.Metin.uygunla("GörevRota — ATLAS rotası"))

    for i = 1, SATIR_SAYISI do
        local s = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        s:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -34 - (i - 1) * SATIR_YUKSEKLIGI)
        s:SetWidth(332)
        s:SetJustifyH("LEFT")
        s:SetWordWrap(false)
        self.satirlar[i] = s
    end

    self.altBilgi = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.altBilgi:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 12)
    self.cerceve = f
end

-- Bir adımın renkli satır metni
local function satirMetni(i, adim)
    local renk = ns.Metin.TUR_RENGI[adim.tur] or "ffffff"
    local metin = ns.Metin.adim(i, adim)
    if i == 1 then
        metin = metin .. "  <- ŞİMDİ"
    end
    return OK .. " |cff" .. renk .. ns.Metin.uygunla(metin) .. "|r"
end

-- Planı panele yazar (paneli açıp kapatmaz)
function ListePaneli:guncelle(plan)
    self:olustur()
    local adimlar = plan.adimlar
    for i = 1, SATIR_SAYISI do
        if adimlar[i] then
            self.satirlar[i]:SetText(satirMetni(i, adimlar[i]))
        else
            self.satirlar[i]:SetText("")
        end
    end
    if #adimlar == 0 then
        self.satirlar[1]:SetText(ns.Metin.uygunla(ns.Metin.DURAK_YOK))
    end

    local alt = string.format("Toplam ~%s · %d adım · çözücü: %s", ns.Metin.sure(plan.toplamSure), #adimlar, plan.cozucu)
    if #adimlar > SATIR_SAYISI then
        alt = alt .. string.format(" · +%d adım daha", #adimlar - SATIR_SAYISI)
    end
    if #plan.ulasilamaz > 0 then
        alt = alt .. string.format(" · %d ulaşılamaz", #plan.ulasilamaz)
    end
    self.altBilgi:SetText(ns.Metin.uygunla(alt))
end

function ListePaneli:ac()
    self:olustur()
    self.cerceve:Show()
end

function ListePaneli:acKapa()
    self:olustur()
    if self.cerceve:IsShown() then
        self.cerceve:Hide()
    else
        self.cerceve:Show()
    end
end

ns.ListePaneli = ListePaneli
