-- arayuz/yon_oku.lua
-- Sıradaki durağa oyunun kendi yön okunu çevirir.
--   Görev durağı (HEDEF / TESLİM) : oyunun görev takibi (SetSuperTrackedQuestID)
--   Diğerleri (AL, uçuş, elle)     : haritaya yer işareti koyup onu takip et

local _, ns = ...

local YonOku = {}
YonOku.__index = YonOku

-- api: { C_Map, C_SuperTrack, UiMapPoint }
function YonOku.yeni(api)
    return setmetatable({ api = api }, YonOku)
end

-- Dönüş: ok çevrildiyse true
function YonOku:hedefle(adim)
    local api = self.api
    if not adim or not api.C_SuperTrack then
        return false
    end

    local d = adim.durak
    if d and type(d.gorevId) == "number" and adim.tur ~= "AL" then
        api.C_SuperTrack.SetSuperTrackedQuestID(d.gorevId)
        return true
    end

    local k = adim.konum
    if not k or not k.harita or not api.C_Map.SetUserWaypoint then
        return false
    end
    if api.C_Map.CanSetUserWaypointOnMap and not api.C_Map.CanSetUserWaypointOnMap(k.harita) then
        return false
    end
    api.C_Map.SetUserWaypoint(api.UiMapPoint.CreateFromCoordinates(k.harita, k.hx, k.hy))
    api.C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    return true
end

ns.YonOku = YonOku
