-- tests/eklenti_test.lua
-- Uçtan uca test: eklentinin TAMAMI, .toc dosyasındaki sırayla, sahte WoW ortamına yüklenir.
-- Sonra oyuncu /gr komutları yazmış ve oyun olaylar göndermiş gibi davranılır.

local T = dofile("tests/yardimci.lua")
local S = dofile("tests/sahte_wow.lua")

T.baslik("Eklenti — .toc ile yükleme (sahte WoW ortamı)")
S.sifirla()
S.globalleriKur()
_G.GorevRotaDB = nil

-- .toc'u oku: '#' ile başlamayan dolu satırlar dosya adıdır
local ns = {}
local dosyaSayisi = 0
for satir in io.lines("GorevRota/GorevRota.toc") do
    if satir ~= "" and not satir:match("^#") then
        local yol = "GorevRota/" .. satir:gsub("\\", "/")
        local parca, hata = loadfile(yol)
        assert(parca, hata)
        parca("GorevRota", ns)
        dosyaSayisi = dosyaSayisi + 1
    end
end
T.esit(dosyaSayisi, 13, ".toc'taki 13 dosyanın hepsi hatasız yüklendi")

S.olayAtesle("ADDON_LOADED", "BaskaEklenti")
T.esit(_G.SlashCmdList.GOREVROTA, nil, "başka eklentinin yüklenmesi bizi kurmaz")
S.olayAtesle("ADDON_LOADED", "GorevRota")
T.dogru(type(_G.SlashCmdList.GOREVROTA) == "function", "/gr komutu kaydedildi")
T.esit(_G.SLASH_GOREVROTA1, "/gr", "kısa komut /gr")
T.dogru(type(_G.GorevRotaDB) == "table", "kayıtlı veri tablosu oluşturuldu")
T.dogru(S.mesajVarMi("yüklendi"), "sohbete 'yüklendi' yazıldı")

local gr = _G.SlashCmdList.GOREVROTA

-- Ekrana yazılan metinlerde ı, ş, ğ dönüştürüldüğü için aramayı da dönüştürerek yap
local function yazildiMi(parca)
    return S.mesajVarMi(ns.Metin.uygunla(parca))
end

T.baslik("Eklenti — /gr komutları (Command)")
S.mesajlar = {}
gr("")
T.dogru(S.mesajVarMi("/gr plan"), "boş komut yardımı gösterir")

S.mesajlar = {}
gr("plan")
local plan = ns.cephe.sonPlan
T.dogru(plan ~= nil, "/gr plan bir plan üretti")
T.esit(plan.cozucu, "ATLAS", "plan ATLAS ile hesaplandı")
T.dogru(yazildiMi("adım planlandı"), "sohbete özet yazıldı")
T.dogru(yazildiMi("plana alınmadı"), "başka kıtadaki görev için uyarı verildi")

local panel = ns.cephe.panel
T.dogru(panel.cerceve:IsShown(), "panel açıldı")
T.dogru(panel.satirlar[1]:GetText():find("SIMDI", 1, true) ~= nil, "ilk satır 'SIMDI' ile işaretli")
T.dogru(panel.satirlar[1]:GetText():find("UI-SpellbookIcon-NextPage", 1, true) ~= nil, "satır başında ok var")
T.dogru(panel.altBilgi:GetText():find("ATLAS", 1, true) ~= nil, "alt bilgide çözücü adı var")
T.dogru(S.takipGorevi ~= nil, "yön oku sıradaki durağa çevrildi")

S.mesajlar = {}
gr("list")
T.dogru(S.mesajVarMi("1. "), "/gr list sıralı listeyi yazdı")

gr("panel")
T.esit(panel.cerceve:IsShown(), false, "/gr panel paneli kapattı")
gr("panel")
T.esit(panel.cerceve:IsShown(), true, "/gr panel tekrar açtı")

T.baslik("Eklenti — elle durak ekleme")
S.mesajlar = {}
gr("ekle hedef 15 15 Çiçek Topla")
T.esit(#_G.GorevRotaDB.elle, 1, "elle durak kaydedildi")
T.esit(_G.GorevRotaDB.elle[1].hx, 0.15, "koordinat 15 -> 0.15")
local elleVar = false
for _, a in ipairs(ns.cephe.sonPlan.adimlar) do
    if a.durak and a.durak.gorevAdi == "Çiçek Topla" then
        elleVar = true
    end
end
T.dogru(elleVar, "elle durak plana girdi")
-- Oyuncuya en yakın durak bu (0.10'dan 0.15'e): ilk adım olmalı
T.esit(ns.cephe.sonPlan.adimlar[1].durak.gorevAdi, "Çiçek Topla", "en yakın durak ilk sırada")
T.esit(S.yerIsareti and S.yerIsareti.uiMapID, 1, "elle durak için haritaya yer işareti kondu")

gr("tamam")
T.esit(#_G.GorevRotaDB.elle, 0, "/gr tamam elle durağı sildi")

gr("ekle teslim")
T.esit(_G.GorevRotaDB.elle[1].ad, "Durak", "ad verilmezse 'Durak'")
T.esit(_G.GorevRotaDB.elle[1].hx, 0.10, "koordinat verilmezse oyuncunun yeri")
gr("temizle")
T.esit(#_G.GorevRotaDB.elle, 0, "/gr temizle hepsini sildi")

S.mesajlar = {}
gr("ekle uç 1 2 x")
T.dogru(yazildiMi("Kullanım"), "yanlış türde kullanım bilgisi gösterilir")
gr("bilinmeyen")
T.dogru(S.mesajVarMi("Bilinmeyen komut"), "bilinmeyen komut bildirilir")

T.baslik("Eklenti — oyun olayları (Observer)")
-- Görev alınınca: teslim yeri kaydedilir, 1 sn sonra plan yenilenir
S.oyuncu = { harita = 1, hx = 0.30, hy = 0.30 }
table.insert(S.gorevler, { title = "Yeni Görev", questID = 105, tamam = false, harita = 1, x = 0.35, y = 0.30 })
S.olayAtesle("QUEST_ACCEPTED", 105)
T.dogru(_G.GorevRotaDB.teslimYerleri[105] ~= nil, "QUEST_ACCEPTED: teslim yeri kaydedildi")
S.olayAtesle("QUEST_LOG_UPDATE")
S.olayAtesle("QUEST_LOG_UPDATE")
T.esit(#S.zamanlayicilar, 1, "art arda gelen olaylar tek bir güncellemede birleşti")
S.zamanGecir()
local yeniAdimlar = 0
for _, a in ipairs(ns.cephe.sonPlan.adimlar) do
    if a.durak and a.durak.gorevId == 105 then
        yeniAdimlar = yeniAdimlar + 1
    end
end
T.esit(yeniAdimlar, 2, "yeni görevin HEDEF ve TESLİM durakları plana girdi")

S.olayAtesle("QUEST_TURNED_IN", 105, 100, 0)
T.esit(_G.GorevRotaDB.teslimYerleri[105], nil, "QUEST_TURNED_IN: teslim yeri silindi")

S.mesajlar = {}
S.olayAtesle("TAXIMAP_OPENED")
T.esit(#ns.cephe:ucusListesi(), 2, "TAXIMAP_OPENED: 2 uçuş noktası kaydedildi")
T.dogru(yazildiMi("uçuş noktası kaydedildi"), "sohbete bildirildi")

S.oyuncu = nil
S.mesajlar = {}
gr("plan")
T.dogru(S.mesajVarMi("Konumun okunamad"), "konum yoksa (zindan) anlaşılır uyarı")

T.baslik("Metinler")
T.esit(ns.Metin.sure(45), "45 sn", "45 sn")
T.esit(ns.Metin.sure(200), "3 dk 20 sn", "200 sn -> 3 dk 20 sn")
T.esit(ns.Metin.sure(120), "2 dk", "120 sn -> 2 dk")
T.esit(ns.Metin.uygunla("Işık Şiş Dağ"), "Isik Sis Dag", "ı ş ğ İ Ş harfleri yazı tipine uygunlaştırıldı")
