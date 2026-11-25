-- GorevRotaCephesi.lua
-- FACADE deseni: komutların ve olayların tek giriş noktası.
-- Arkadaki alt sistemleri (adaptör, planlayıcı, panel, yön oku, kayıtlı veri)
-- tek bir sade arayüzün arkasına saklar: planla(), listeYaz(), durakEkle() ...
--
-- Cephe somut oyun fonksiyonlarını bilmez; ihtiyacı olan her şey ona verilir (DIP).

local _, ns = ...
local M = ns.Metin

local GorevRotaCephesi = {}
GorevRotaCephesi.__index = GorevRotaCephesi

-- b (bağımlılıklar):
--   adaptor    : WowGorevAdaptoru       planlayici : Planlayici
--   panel      : ListePaneli            yonOku     : YonOku
--   db         : kayıtlı veri tablosu (GorevRotaDB)
--   yazdir     : function(metin)        — sohbet penceresine yazar
--   zamanla    : function(sn, fonksiyon) — sonra çalıştırır (C_Timer.After)
function GorevRotaCephesi.yeni(b)
    local c = setmetatable({}, GorevRotaCephesi)
    for ad, deger in pairs(b) do
        c[ad] = deger
    end
    c.db.teslimYerleri = c.db.teslimYerleri or {}
    c.db.ucuslar = c.db.ucuslar or {}
    c.db.elle = c.db.elle or {}
    c.sonPlan = nil
    c.planBekliyor = false
    return c
end

function GorevRotaCephesi:yaz(metin)
    self.yazdir(M.ONEK .. M.uygunla(metin))
end

-- Elle eklenen durakları modele çevirir
function GorevRotaCephesi:elleDuraklar()
    local liste = {}
    for i, e in ipairs(self.db.elle) do
        local d = ns.DurakOlustur({
            gorevId = "elle:" .. e.ad,   -- aynı adlı duraklar aynı "görev" sayılır (AL < HEDEF < TESLİM)
            gorevAdi = e.ad,
            tur = e.tur,
            konum = self.adaptor:haritaKonumunuCevir(e.harita, e.hx, e.hy),
        })
        d.elleNo = i
        table.insert(liste, d)
    end
    return liste
end

function GorevRotaCephesi:ucusListesi()
    local liste = {}
    for _, u in pairs(self.db.ucuslar) do
        table.insert(liste, u)
    end
    table.sort(liste, function(a, b) return a.ad < b.ad end)   -- her seferinde aynı sıra
    return liste
end

-- Asıl iş: oku -> planla -> göster -> yön okunu çevir
-- sessiz = true: olaylardan gelen otomatik güncelleme (sohbete yazmaz, paneli zorla açmaz)
function GorevRotaCephesi:planla(sessiz)
    local oyuncu = self.adaptor:oyuncuKonumu()
    if not oyuncu then
        if not sessiz then
            self:yaz(M.KONUM_YOK)
        end
        return nil
    end
    local duraklar = self.adaptor:duraklariOku(self.db.teslimYerleri)
    for _, d in ipairs(self:elleDuraklar()) do
        table.insert(duraklar, d)
    end

    local plan = self.planlayici:planla(oyuncu, duraklar, self:ucusListesi())
    self.sonPlan = plan
    self.panel:guncelle(plan)
    self.yonOku:hedefle(plan.adimlar[1])

    if not sessiz then
        self.panel:ac()
        self:yaz(string.format("%d adım planlandı (%s ile, toplam ~%s).",
            #plan.adimlar, plan.cozucu, M.sure(plan.toplamSure)))
        if #plan.ulasilamaz > 0 then
            self:yaz(#plan.ulasilamaz .. " durak bu kıtada değil ya da konumu bilinmiyor; plana alınmadı.")
        end
    end
    return plan
end

-- Olaylar çok sık gelir (QUEST_LOG_UPDATE); 1 sn bekleyip tek sefer planla.
-- Kullanıcı henüz /gr plan yazmadıysa hiçbir şey yapma.
function GorevRotaCephesi:gecikmeliPlanla()
    if not self.sonPlan or self.planBekliyor then
        return
    end
    self.planBekliyor = true
    self.zamanla(1, function()
        self.planBekliyor = false
        self:planla(true)
    end)
end

function GorevRotaCephesi:listeYaz()
    local plan = self.sonPlan or self:planla(true)
    if not plan then
        self:yaz(M.PLAN_YOK)
        return
    end
    if #plan.adimlar == 0 then
        self:yaz(M.DURAK_YOK)
    end
    for i, adim in ipairs(plan.adimlar) do
        self:yaz(M.adim(i, adim))
    end
end

function GorevRotaCephesi:paneliAcKapa()
    if not self.sonPlan then
        self:planla(true)
    end
    self.panel:acKapa()
end

-- tur: "AL" | "HEDEF" | "TESLIM";  hx, hy verilmezse oyuncunun bulunduğu yer
function GorevRotaCephesi:durakEkle(tur, ad, hx, hy)
    local oyuncu = self.adaptor:oyuncuKonumu()
    if not oyuncu then
        self:yaz(M.KONUM_YOK)
        return
    end
    table.insert(self.db.elle, { tur = tur, ad = ad, harita = oyuncu.harita, hx = hx or oyuncu.hx, hy = hy or oyuncu.hy })
    self:yaz(string.format("Durak eklendi: %s (%s)", ad, M.TUR_ADI[tur]))
    if self.sonPlan then
        self:planla(true)
    end
end

-- Sıradaki adım elle eklenmiş bir duraksa onu sil
function GorevRotaCephesi:ilkDuragiTamamla()
    local ilk = self.sonPlan and self.sonPlan.adimlar[1]
    if not ilk then
        self:yaz(M.PLAN_YOK)
        return
    end
    if not (ilk.durak and ilk.durak.elleNo) then
        self:yaz(M.OYUN_TAKIP)
        return
    end
    table.remove(self.db.elle, ilk.durak.elleNo)
    self:yaz("Tamamlandı: " .. ilk.durak.gorevAdi)
    self:planla(true)
end

function GorevRotaCephesi:elleDuraklariTemizle()
    self.db.elle = {}
    self:yaz("Elle eklenen duraklar silindi.")
    if self.sonPlan then
        self:planla(true)
    end
end

-- QUEST_ACCEPTED: görev alındığı yer çoğu zaman teslim yeridir (görevi veren kişi)
function GorevRotaCephesi:gorevAlindi(gorevId)
    local konum = self.adaptor:oyuncuKonumu()
    if konum and gorevId then
        self.db.teslimYerleri[gorevId] = konum
    end
    self:gecikmeliPlanla()
end

-- QUEST_TURNED_IN / QUEST_REMOVED: artık teslim yerini saklamaya gerek yok
function GorevRotaCephesi:gorevBitti(gorevId)
    if gorevId then
        self.db.teslimYerleri[gorevId] = nil
    end
    self:gecikmeliPlanla()
end

-- TAXIMAP_OPENED: bilinen uçuş noktalarını kaydet
function GorevRotaCephesi:ucusNoktalariniKaydet()
    local sayi = 0
    for _, u in ipairs(self.adaptor:ucusNoktalariniOku()) do
        self.db.ucuslar[u.id] = { ad = u.ad, konum = u.konum }
        sayi = sayi + 1
    end
    if sayi > 0 then
        self:yaz(sayi .. " uçuş noktası kaydedildi.")
    end
end

ns.GorevRotaCephesi = GorevRotaCephesi
