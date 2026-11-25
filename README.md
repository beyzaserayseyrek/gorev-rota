# GörevRota

World of Warcraft için görev takip eklentisi. Görev kütüğündeki görevlerin duraklarını
(görevi alma, hedefler, teslim) **ATLAS** algoritmasıyla sıraya koyar ve oyun içinde
oklarla sıralanmış bir liste panelinde gösterir. Sıradaki durağa oyunun yön oku çevrilir.

> Yazılım Mühendisliği — Tasarım Desenleri dersi ödevi.
> ATLAS algoritması: <https://github.com/savastakan/atlas> (Savaş Takan)
> Tasarım desenleri ve SOLID: [docs/TASARIM.md](docs/TASARIM.md)

```
Görev kütüğü → haritadaki noktalar → ATLAS → sıralı liste paneli
```

---

## 1. Oyunu indirme (macOS)

1. <https://battle.net> adresinde ücretsiz bir Battle.net hesabı açın.
2. Mac için **Battle.net uygulamasını** indirip kurun ve hesabınızla girin.
3. Uygulamada **World of Warcraft**'ı seçin:
   - Aboneliğiniz yoksa **ücretsiz deneme** (Starter Edition, 20. seviyeye kadar) yeterli; eklentiler çalışır.
   - Aboneliğiniz varsa sürüm seçicide **WoW: Forever** de seçilebilir.
4. **Yükle**'ye basın. Oyun büyüktür (yaklaşık 100 GB); internet hızına göre saatler sürebilir.
5. Oyunu bir kez açıp kapatın; eklenti klasörü o zaman oluşur.

## 2. Hazırlık (test için)

WoW eklentileri Lua 5.1 ile çalışır. Çekirdek kod oyun dışında LuaJIT ile test edilir.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install luajit
luajit -v
```

Homebrew kurulumu Mac şifrenizi ister (yazarken ekranda görünmez). Sonunda "Next steps"
altındaki iki komutu da çalıştırın.

## 3. Eklentiyi kurma

Repo kökünden:

```bash
sh araclar/kur.sh             # ücretsiz deneme / güncel sürüm (_retail_)
sh araclar/kur.sh _forever_   # WoW: Forever
```

Betik `GorevRota/` klasörünü şuraya kopyalar:

| Sürüm | Klasör |
|---|---|
| Güncel / deneme | `/Applications/World of Warcraft/_retail_/Interface/AddOns/GorevRota` |
| WoW: Forever | `/Applications/World of Warcraft/_forever_/Interface/AddOns/GorevRota` |

Elle kurmak isterseniz `GorevRota` klasörünü Finder'da bu yola sürükleyin.
Klasörün adı mutlaka `GorevRota` olmalı (içinde `GorevRota.toc` var).

Oyunda karakter seçme ekranında sol alttaki **AddOns** düğmesinden GörevRota'nın işaretli olduğunu kontrol edin.
"Güncel değil" (out of date) yazıyorsa aşağıdaki arayüz numarası adımını yapın.

### Oyunun API'sini kontrol etme

Oyunda bir görev alın ve sohbet kutusuna sırayla yazın:

```
/dump select(4, GetBuildInfo())
/dump C_QuestLog.GetQuestsOnMap(C_Map.GetBestMapForUnit("player"))
/dump GetQuestUiMapID ~= nil, C_SuperTrack ~= nil, C_Map.SetUserWaypoint ~= nil, C_TaxiMap ~= nil
```

1. İlk komut **arayüz numarasını** verir (ör. `120001`). Bu sayı `GorevRota.toc` dosyasının ilk
   satırındaki listede yoksa listeye ekleyin.
2. İkinci komut görevlerin haritadaki koordinatlarını listelemeli (`questID`, `x`, `y`).
3. Üçüncü komutta dört değerin hepsi `true` olmalı.

Koordinatlar okunamazsa duraklar `/gr ekle` komutuyla elle girilebilir (aşağıda).

### Lua hatalarını görme

Oyunda bir kez yazın; hatalar ekranda pencere olarak görünür:

```
/console scriptErrors 1
```

Eklenti dosyasını değiştirdikten sonra oyunda `/reload` yazmak yeterli.

## 4. Komutlar

| Komut | Ne yapar? |
|---|---|
| `/gr plan` | Görev duraklarını ATLAS ile sıralar, paneli açar, yön okunu ilk durağa çevirir |
| `/gr liste` (veya `/gr list`) | Sıralı durakları sohbet penceresine yazar |
| `/gr panel` | Paneli açar / kapatır (panel fareyle sürüklenebilir) |
| `/gr ekle <al\|hedef\|teslim> [x y] <ad>` | Elle durak ekler. `x y` haritadaki koordinattır (0–100); verilmezse bulunduğunuz yer. Ör. `/gr ekle hedef 42.5 65 Kurt Avı` |
| `/gr tamam` | Sıradaki adım elle eklenmiş bir duraksa onu tamamlandı sayar |
| `/gr temizle` | Elle eklenen bütün durakları siler |
| `/gr yardim` | Komut listesi |

`/gorevrota` da `/gr` ile aynıdır.

**Otomatik güncelleme:** `/gr plan` bir kez yazıldıktan sonra görev alınınca (`QUEST_ACCEPTED`),
ilerleyince (`QUEST_LOG_UPDATE`), teslim edilince (`QUEST_TURNED_IN`) ya da bırakılınca
(`QUEST_REMOVED`) liste kendiliğinden yenilenir. Uçuş ustasında uçuş haritasını açtığınızda
(`TAXIMAP_OPENED`) bilinen uçuş noktaları kaydedilir ve rotada kullanılır.

## 5. ATLAS nasıl kullanılıyor?

- `GorevRota/core/atlas.lua`, hocanın `Atlas.java` dosyasının satır satır Lua 5.1 çevirisidir.
  Java'daki adlar yorumlarda yazılıdır (`dfs`, `longestPath`, `comeFrom` ...).
- Örnek grafta (`bbtas.kiss2.fsm`) Java ile **birebir aynı** kenar sırasını ve `atlas: 55`
  sonucunu verir.
- Planlayıcı (`core/planlayici.lua`) görev duraklarını bir grafa çevirir:
  - **düğümler:** oyuncu, duraklar, uçuş noktaları
  - **kenarlar:** yürüme ve uçuş, ağırlığı saniye cinsinden süre
  - **gerekli kenarlar:** her durakta kendine dönen bir kenar; ATLAS bu kenarları kapsayan bir yürüyüş bulur
- Kenarın değeri: yapılmamış durak = `ODUL − süre`, diğerleri `− süre`. ATLAS üç tur çalışır
  (ODUL = 60, 300, sınırsız): önce yakın duraklar, uzaklar en sona.
- Aynı görevde sıra korunur: **al → hedef → teslim**.

Ayrıntı ve diyagramlar: [docs/TASARIM.md](docs/TASARIM.md).

## 6. Testler

Repo kökünden:

```bash
luajit tests/hepsi.lua           # 86 test
sh tests/java_karsilastir.sh     # hocanın Java kodunu indirip çalıştırır, beklenen çıktıyla karşılaştırır (JDK gerekir)
```

| Test dosyası | Neyi sınar? |
|---|---|
| `tests/atlas_test.lua` | ATLAS'ın Lua çevirisi Java ile aynı sonucu veriyor mu? |
| `tests/planlayici_test.lua` | Bütün duraklar planda mı, al → hedef → teslim sırası, uçuş kullanımı, ulaşılamayan duraklar, 40 duraklık senaryoda hız |
| `tests/adaptor_test.lua` | Adapter, sahte oyun API'sini durak modeline doğru çeviriyor mu? |
| `tests/eklenti_test.lua` | Eklentinin tamamı `.toc` sırasıyla sahte WoW ortamına yüklenir; `/gr` komutları, panel, yön oku ve oyun olayları uçtan uca denenir |

`tests/sahte_wow.lua`, oyunun API'sinin (C_QuestLog, C_Map, C_TaxiMap, CreateFrame ...)
küçük bir taklididir. Bu sayede eklenti oyun açılmadan test edilebilir.

## 7. Sınırlar

- **Gerçek oyunda henüz denenmedi.** Testler sahte bir oyun ortamında yapıldı. Arayüz numarası
  (`GorevRota.toc`) tahminidir; oyundaki `/dump` sonucuna göre güncellenmelidir.
- **Yalnızca bulunduğunuz kıta** planlanır. Gemi, portal, zeplin ve ışınlanma (hearthstone)
  kullanılmaz; başka kıtadaki duraklar "ulaşılamaz" diye ayrıca bildirilir.
- **Mesafeler kuş uçuşudur.** Dağlar, sular ve yollar hesaba katılmaz. Yürüme hızı sabit 7 yard/sn
  (binek yok), uçuş süresi düz çizgi + 15 sn binme payıdır.
- **Teslim yeri** görevi aldığınız yer olarak kaydedilir. Eklentiden önce alınmış görevlerin teslim
  yeri, görev bitince oyun haritada gösterene kadar bilinmez.
- **Uçuş noktaları** ancak uçuş ustasında harita açıldığında öğrenilir.
- Bir görevin birden çok hedef bölgesi varsa oyunun haritada gösterdiği tek nokta kullanılır.
- ATLAS bir sezgiseldir; bulduğu rota her zaman en kısa olmayabilir.
- Oyunun yazı tipinde bulunmayabileceği için ekranda ı, ş, ğ harfleri i, s, g olarak yazılır.

## 8. Ekran görüntüleri

Sunum için ekran görüntüleri [docs/ekran/](docs/ekran/) klasöründedir.
Hangi görüntülerin alınacağı o klasördeki README'de listelenmiştir.

## Klasör yapısı

```
GorevRota/                 Eklentinin kendisi (AddOns klasörüne kopyalanır)
  GorevRota.toc            Eklenti tanımı ve dosya sırası
  GorevRota.lua            Giriş noktası: parçaları bağlar
  GorevRotaCephesi.lua     Facade
  core/                    Oyundan bağımsız çekirdek: graf, ATLAS, Strategy, planlayıcı
  oyun/                    Adapter ve Observer
  arayuz/                  Panel, yön oku, metinler
  komutlar/                Command
araclar/kur.sh             Eklentiyi oyuna kopyalar
tests/                     LuaJIT testleri ve sahte WoW ortamı
docs/                      Tasarım belgesi ve ekran görüntüleri
```
