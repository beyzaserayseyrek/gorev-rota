-- core/gorev_modeli.lua
-- Eklentinin kendi görev modeli. Oyunun API'sinden bağımsızdır;
-- oyundan gelen veriyi bu modele WowGorevAdaptoru (Adapter) çevirir.
--
-- Konum alanları:
--   kita       : kıta numarası (aynı kıtadaki yerler arasında yürünebilir)
--   x, y       : kıta üzerindeki konum (yard). Mesafe hesabı bunlarla yapılır.
--   harita     : oyunun harita numarası (uiMapID) — yön oku için
--   hx, hy     : o haritadaki konum (0..1) — yön oku için

local _, ns = ...

-- Bir görevin durak türleri ve sırası: önce al, sonra hedefleri yap, en son teslim et.
ns.DurakTuru = { AL = "AL", HEDEF = "HEDEF", TESLIM = "TESLIM" }
ns.TurSirasi = { AL = 1, HEDEF = 2, TESLIM = 3 }

local sayac = 0

-- Yeni bir durak oluşturur.
-- bilgi: { gorevId, gorevAdi, tur, konum }
function ns.DurakOlustur(bilgi)
    assert(ns.TurSirasi[bilgi.tur], "Bilinmeyen durak türü: " .. tostring(bilgi.tur))
    sayac = sayac + 1
    return {
        id = sayac,
        gorevId = bilgi.gorevId,
        gorevAdi = bilgi.gorevAdi or "?",
        tur = bilgi.tur,
        konum = bilgi.konum,
    }
end
