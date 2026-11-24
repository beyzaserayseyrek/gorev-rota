# GörevRota

World of Warcraft için görev takip eklentisi. Görev kütüğündeki görevlerin duraklarını
(görevi alma, hedefler, teslim) **ATLAS** algoritmasıyla sıraya koyar ve oyun içinde
sıralı bir liste panelinde gösterir.

> Yazılım Mühendisliği — Tasarım Desenleri dersi ödevi.
> ATLAS: <https://github.com/savastakan/atlas>

## Hazırlık (macOS)

WoW eklentileri Lua 5.1 ile çalışır. Çekirdek kodu oyun dışında test etmek için LuaJIT kullanıyoruz.

1. Homebrew'u kurun (Mac şifrenizi ister; yazarken ekranda görünmez):

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   Kurulumun sonunda "Next steps" altındaki iki komutu da çalıştırın.

2. LuaJIT'i kurun ve kontrol edin:

   ```bash
   brew install luajit
   luajit -v
   ```

## Klasör yapısı

```
GorevRota/        Eklentinin kendisi (oyunun AddOns klasörüne kopyalanır)
  core/           Oyundan bağımsız çekirdek (ATLAS, planlayıcı)
tests/            LuaJIT ile çalışan testler
docs/             Tasarım belgesi ve ekran görüntüleri
```

_Kurulum, komutlar ve ayrıntılar sonraki adımlarda eklenecek._
