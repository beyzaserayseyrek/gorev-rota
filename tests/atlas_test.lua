-- tests/atlas_test.lua
-- Lua'ya çevirdiğimiz ATLAS, hocanın Java kodu ile AYNI sonucu veriyor mu?
-- Beklenen değerler tests/veri/java_beklenen.txt dosyasında; o dosya
-- tests/java_karsilastir.sh ile hocanın Java kodu çalıştırılarak üretildi.

local T = dofile("tests/yardimci.lua")
local fsmOku = dofile("tests/fsm_oku.lua")
local ns = T.yukle(T.CEKIRDEK)

T.baslik("ATLAS çekirdeği — bbtas.kiss2.fsm, Java ile karşılaştırma")

local java = T.satirlar("tests/veri/java_beklenen.txt")
-- 1. satır: "atlas: 55"  (Main.java çıktısı)
-- 2. satır: printPath çıktısı
-- 3. satır: getTestSuite çıktısı

local graf = fsmOku(ns, "tests/veri/bbtas.kiss2.fsm")
T.esit(graf.kenarSayisi, 24, "graf 24 kenar içeriyor")
T.esit(#graf.baslangiclar, 4, "0 durumundan çıkan 4 başlangıç kenarı var")

local yol = ns.Atlas.enUzunYol(graf, graf.baslangiclar[1])
T.esit(ns.Atlas.yolMetni(graf, yol), java[2], "kenar sırası Java printPath ile aynı")
T.esit(ns.Atlas.testDizisi(graf, yol), java[3], "test dizisi Java getTestSuite ile aynı")
T.esit("atlas: " .. #ns.Atlas.calistir(graf), java[1], "Main.java çıktısı ile aynı")

T.baslik("ATLAS çekirdeği — küçük elle kontrol edilebilir graf")
-- 1 -> 2 -> 3 -> 1 üçgeni: bütün kenarlar tek turda dolaşılmalı
local ucgen = ns.Graf.yeni()
local a = ucgen:kenarEkle(1, 2, "a", 0, 1)
ucgen:kenarEkle(2, 3, "b", 0, 1)
ucgen:kenarEkle(3, 1, "c", 0, 1)
local ucgenYol, son = ns.Atlas.enUzunYol(ucgen, a)
table.insert(ucgenYol, son)
T.esit(ns.Atlas.testDizisi(ucgen, ucgenYol), "a,b,c", "üçgende a, b, c sırası")

-- Çıkışı olmayan kenar (Java'da dizi hatası verirdi): sorunsuz bitmeli
local tek = ns.Graf.yeni()
local t = tek:kenarEkle(1, 2, "t", 0, 1)
local tekYol, tekSon = ns.Atlas.enUzunYol(tek, t)
T.esit(#tekYol, 0, "çıkmaz kenarda yol boş döner")
T.esit(tekSon, t, "ve son kenar başlangıç kenarıdır")
