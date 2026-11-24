-- core/graf.lua
-- Yönlü graf. Hocanın Graph.java ve Edge.java sınıflarının Lua karşılığı.
-- Oyundan bağımsızdır: hem WoW içinde hem LuaJIT testlerinde aynen çalışır.

-- WoW her eklenti dosyasını (eklentiAdi, ns) argümanlarıyla çalıştırır.
-- ns: eklentinin bütün dosyalarının paylaştığı ortak tablo ("isim alanı").
local _, ns = ...

local Graf = {}
Graf.__index = Graf

-- Boş bir graf oluşturur.
function Graf.yeni()
    local g = setmetatable({}, Graf)
    g.dugumler = {}      -- düğüm -> o düğümden çıkan kenar etiketleri (ekleniş sırasıyla)
    g.kenarlar = {}      -- etiket -> kenar
    g.kenarSayisi = 0
    g.baslangiclar = {}  -- başlangıç kenarlarının etiketleri (Java: starts)
    return g
end

function Graf:dugumEkle(d)
    if not self.dugumler[d] then
        self.dugumler[d] = {}
    end
end

-- Java: addEdge(label, source, destination, input, output, weight)
-- Etiketi biz veriyoruz (1, 2, 3 ...). 'veri' alanı planlayıcının kendi bilgisi içindir.
function Graf:kenarEkle(kaynak, hedef, girdi, cikti, agirlik, veri)
    self:dugumEkle(kaynak)
    self:dugumEkle(hedef)
    self.kenarSayisi = self.kenarSayisi + 1
    local etiket = self.kenarSayisi
    self.kenarlar[etiket] = {
        etiket = etiket,
        kaynak = kaynak,
        hedef = hedef,
        girdi = girdi,
        cikti = cikti,
        agirlik = agirlik or 1,
        veri = veri or {},
    }
    table.insert(self.dugumler[kaynak], etiket)
    return etiket
end

-- Java: getEdge(label)
function Graf:kenar(etiket)
    return self.kenarlar[etiket]
end

-- Java: edgeLabels(node) — düğümden çıkan kenarlar.
-- Not: Java'da bu bir HashSet; küçük tamsayılarda küçükten büyüğe dolaşılır.
-- Biz ekleniş sırasını tutuyoruz; örnek grafta ikisi aynı sırayı verir.
function Graf:cikanKenarlar(d)
    return self.dugumler[d] or {}
end

function Graf:baslangicEkle(etiket)
    table.insert(self.baslangiclar, etiket)
end

ns.Graf = Graf
