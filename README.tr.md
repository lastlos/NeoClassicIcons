# NeoClassicIcons

**Lazarus için klasik 16×16 piksel-art ikonlar.** Windows 9x/2000 ve Delphi 7 ruhunda, yanında forma bırakınca hazır gelen bir ImageList bileşeniyle.

[English](README.md) · [İkon listesi](docs/ICONS.md) · [Katkı](CONTRIBUTING.md) · [Değişiklikler](CHANGELOG.md)

![Araç çubuğu](docs/toolbar.png)

![Tüm ikonlar](docs/preview.png)

## Özellikler

- **78 ikon**, altı kategoride: dosya, düzen, işlem, gezinme, veri ve genel uygulama ikonları.
- **Klasik 16 renk paletinde piksel art.** Her ikon 16×16 olarak elle çizildi. 32×32 sürümleri pikseller ikiye katlanarak üretildi, bu yüzden HiDPI ekranda da keskin kalır.
- **`TNeoClassicImageList`**: Forma bıraktığınızda tüm ikonlar içinde hazır gelir. Nesne Denetçisi'nden seçebilir ya da `nciDocumentSave` gibi okunaklı sabitler kullanabilirsiniz.
- **`.lfm` dosyanıza görüntü verisi yazılmaz.** İkonlar kaynak (resource) olarak bağlanır; formlar küçük, diff'ler temiz kalır.
- **HiDPI uyumlu.** 16, 24 ve 32 px çözünürlükleri vardır. `Scaled` araç çubukları, menüler ve düğmeler keskin boyutu kendileri seçer.
- **Sabit indeksler.** Bir ikonun indeksi sürümler arasında asla değişmez; yeni ikonlar hep sona eklenir.
- **İsteğe bağlı klasik tema.** Linux/GTK2'de `NeoClassicTheme` birimi uygulamanıza gri Windows 2000 görünümü verir, masaüstü temanıza dokunmaz.
- Başka işler için **düz PNG dosyaları** `icons/16` ve `icons/32` klasörlerinde.
- **MIT lisanslı.**

## Ekran görüntüleri

Demo uygulaması, Linux/GTK2'de `NeoClassicTheme` ile:

![Demo - ikon görünümü](docs/demo-icons.png)

![Demo - ayrıntı görünümü](docs/demo-details.png)

## Kurulum

Gereksinim: Lazarus 3.0 ve FPC 3.2.2 ile test edildi. Daha eski sürümler denenmedi; çok çözünürlüklü ImageList için en az Lazarus 2.0 gerekir.

1. Depoyu klonlayın ya da indirin.
2. Lazarus'ta **Paket → Paket Dosyası Aç (.lpk)…** ile `package/neoclassicicons.lpk` dosyasını açın.
3. Önce **Derle**, sonra **Kullan → Kur** deyin ve IDE'nin yeniden derlenmesine izin verin.

IDE yeniden açıldığında `TNeoClassicImageList` bileşenini paletteki **NeoClassic** sekmesinde bulursunuz.

**IDE'ye kurmadan kullanmak:** **Proje → Proje Denetçisi → Ekle → Yeni Gereksinim** ile `neoclassicicons` paketini projenize ekleyin, sonra listeyi kodla oluşturun (aşağıya bakın).

## Kullanım

### Form tasarımcısında

1. Forma bir `TNeoClassicImageList` bırakın. Tüm ikonlar içinde hazırdır.
2. Bu listeyi `TToolBar`, `TMainMenu`, `TActionList`, `TBitBtn`, `TSpeedButton` ya da `TListView` bileşeninin `Images` özelliğine verin. İkonları Nesne Denetçisi'nde `ImageIndex` ile seçin.
3. Normal DPI'da 32 px ikon istiyorsanız (örneğin büyük bir araç çubuğu için) listenin `Width` ve `Height` değerlerini 32 yapın.

### Kodda

```pascal
uses
  NeoClassicImageList, NeoClassicIconNames;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Ikonlar := TNeoClassicImageList.Create(Self);
  ToolBar1.Images := Ikonlar;
  tbKaydet.ImageIndex := nciDocumentSave;
  tbYazdir.ImageIndex := nciDocumentPrint;
  btnSil.ImageIndex := Ikonlar.IndexOfName('edit_delete');  // adla
end;
```

Paketteki diğer yardımcılar:

| Yordam | Ne işe yarar |
|---|---|
| `NeoClassicLoadIcons(HerhangiBirImageList)` | Tüm ikonları mevcut bir `TImageList`'e ekler. Liste boşsa `nciXxx` sırasıyla eklenir. |
| `NeoClassicCreateIcon('folder_open', 32)` | Tek bir ikonu `TPortableNetworkGraphic` olarak verir (16 ya da 32 px). Serbest bırakmak çağırana düşer. |
| `NeoClassicIconIndex('folder_open')` | Adın indeksini döndürür; ad bilinmiyorsa -1. |
| `NeoClassicIconList[i]`, `NeoClassicIconTitles[i]` | Her ikonun adı ve açıklaması. |

### Klasik Windows 2000 / Delphi 7 görünümü (isteğe bağlı, GTK2)

`.lpr` dosyanızda `NeoClassicTheme` birimini `Interfaces`'ten **önce** yazın:

```pascal
uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  NeoClassicTheme,   // Interfaces'ten önce gelmeli
  Interfaces, Forms, Unit1;
```

Tema yalnızca sizin uygulamanızı etkiler, masaüstüne dokunmaz. Gri `#D4D0C8` yüzeyler, lacivert seçim, kabartmalı kontroller ve sarı ipuçları getirir.

- Kabartmalı çizim `gtk2-engines` paketindeki `redmond95` motorundan gelir. Bu motor yoksa renkler yine uygulanır.
- Windows, Qt ve Cocoa'da, ayrıca Lazarus IDE'nin içinde birim hiçbir şey yapmaz.
- Çalışma anında kapatmak için `NEOCLASSIC_THEME=0` ortam değişkenini kullanın.

## İkonları derlemek

Her ikon, `src/` altında 16×16'lık bir metin dosyasıdır; her piksel bir palet karakteridir. Gerisini `tools/build.py` üretir:

```sh
python3 tools/build.py           # icons/, package/*.res, package/neoclassiciconnames.pas ve docs/ yeniden üretilir
python3 tools/build.py --check   # depodaki üretilmiş dosyalar src/ ile uyuşuyor mu (CI kullanır)
```

Üretilen dosyalar depoda hazır durur, yani **paketi kullanmak için Python gerekmez**. İkon eklemek ya da değiştirmek için [CONTRIBUTING.md](CONTRIBUTING.md) dosyasına bakın.

## Lisans

[MIT](LICENSE) © 2026 OpenLast. Lisans hem ikonları hem kodu kapsar.

`NeoClassicTheme` stili, gtk2-engines'in "Redmond" temasından (LGPL) uyarlanmıştır. Yalnızca renk ve ölçü ayarları alındı; çizim motorunun kendisi kullanıcının sisteminden yüklenir.
