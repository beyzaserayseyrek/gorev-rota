-- tests/adaptor_test.lua
-- WowGorevAdaptoru (Adapter): sahte oyun API'sini görev modelimize doğru çeviriyor mu?

local T = dofile("tests/yardimci.lua")
local S = dofile("tests/sahte_wow.lua")
local dosyalar = {}
for _, d in ipairs(T.CEKIRDEK) do
    table.insert(dosyalar, d)
end
table.insert(dosyalar, "GorevRota/oyun/wow_gorev_adaptoru.lua")
local ns = T.yukle(dosyalar)

T.baslik("Adapter — oyun API'si -> görev modeli")
S.sifirla()
local adaptor = ns.WowGorevAdaptoru.yeni(S.api())

local oyuncu = adaptor:oyuncuKonumu()
T.esit(oyuncu.kita, 0, "oyuncunun kıtası okundu")
T.esit(oyuncu.x, 100, "harita konumu 0.10 -> 100 yard")
T.esit(oyuncu.harita, 1, "harita numarası saklandı (yön oku için)")

local duraklar = adaptor:duraklariOku({ [101] = { kita = 0, x = 50, y = 50, harita = 1, hx = 0.05, hy = 0.05 } })
-- Beklenen: Kurt Avı HEDEF + TESLIM (teslim yeri biliniyor), Mektup TESLIM, Uzak Diyar HEDEF
T.esit(#duraklar, 4, "başlık ve gizli görev atlandı, 4 durak üretildi")
T.esit(duraklar[1].gorevAdi .. "/" .. duraklar[1].tur, "Kurt Avı/HEDEF", "bitmemiş görev -> HEDEF")
T.esit(duraklar[1].konum.x, 400, "hedefin konumu harita işaretinden okundu")
T.esit(duraklar[2].tur, "TESLIM", "teslim yeri biliniyorsa TESLİM durağı da eklendi")
T.esit(duraklar[3].gorevAdi .. "/" .. duraklar[3].tur, "Mektup/TESLIM", "bitmiş görev -> yalnızca TESLİM")
T.esit(duraklar[4].konum.kita, 1, "başka kıtadaki görevin kıtası doğru")

local ucuslar = adaptor:ucusNoktalariniOku()
T.esit(#ucuslar, 2, "ulaşılamayan uçuş noktası atlandı")
T.esit(ucuslar[1].ad, "Goldshire", "uçuş noktasının adı okundu")

S.oyuncu = nil
T.esit(adaptor:oyuncuKonumu(), nil, "konum bilinmiyorsa (ör. zindan) nil döner")

-- Uçtan uca: adaptörün ürettiği duraklar planlayıcıda çalışıyor mu?
S.sifirla()
local plan = ns.Planlayici.yeni(ns.AtlasCozucu):planla(adaptor:oyuncuKonumu(), adaptor:duraklariOku({}),
    adaptor:ucusNoktalariniOku())
T.esit(#plan.ulasilamaz, 1, "başka kıtadaki görev ulaşılamaz listesinde")
T.dogru(#plan.adimlar >= 2, "kalan görevler için plan çıktı")
