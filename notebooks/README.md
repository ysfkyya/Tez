# `notebooks/` — FAZ 3.5 notebook'ları

Veri kalitesi ölçümlerini üç notebook'a böldük. Bölme konuya göre değil, **amaca göre**:
her notebook'un farklı bir okuyucusu ve farklı bir çalıştırılma sıklığı var.

| Defter | Kimin için | Ne zaman | Ağırlık |
|---|---|---|---|
| `data-quality-dashboard.ipynb` | sen — doğrulama | her `make features` sonrası | hafif (~360KB) |
| `advisor-demo.ipynb` | danışman — sunum | gösterimden önce | hafif (~300KB) |
| `parquet-explorer.ipynb` | sen — araç | ham veriye bakarken | ağır (~1,5MB, itables) |

**Ortak görünüm katmanı** `style.py` ve `charts.py` içinde: sırasıyla palette ile tema,
ve birden çok notebook'un paylaştığı grafikler. Bunları her notebook'ta yeniden yazmıyoruz,
çünkü iki kopya zamanla ayrışır ve doğrulanmış palette sessizce bozulur.

## İki kural

**1. Ölçüm mantığı notebook'ta yazılmaz.** `normal_runtime_coverage`, `separability`,
`best_discriminator`, `is_degenerate`, `check_targets` ve `TARGETS`, hepsi
`src/validate_dataset.py` dosyasından; feature şeması
`src/features/extract_features.py` dosyasından import ediliyor. Böylece notebook'lar
`make validate` ile çelişemiyor ve ölçüm mantığının ikinci bir kopyası doğmuyor.

**2. Defterlerde elle yazılmış ölçüm yok.** Her sayı çalıştırma anında
`features.parquet` dosyasından hesaplanıyor. Kanonik sayılar
[`roadmap/00-durum.md`](../roadmap/00-durum.md) dosyasında yaşıyor; buraya
kopyalanmıyor, çünkü kopyalanan sayı eskiyor. `advisor-demo.ipynb` faz indeksini bile
`roadmap/README.md` dosyasından canlı okuyor.

## Dil ve sözlük

Teknik terimler İngilizce (notebook, dashboard, feature, label, window, baseline,
fusion, heatmap, boxplot), açıklamalar Türkçe; tez Türkçe olduğu için
metinler Türkçe kalıyor. Kod tanımlayıcıları da İngilizce, çünkü repo'nun kendi düzeni
öyle (`src/validate_dataset.py`).

> **Tek istisna:** kabul kriterleri tablosunun satır adları `vd.check_targets`
> içinden geldiği için Türkçe kalıyor. Onları İngilizceye çevirmek aynı kriter için
> ikinci bir ad yaratırdı; sözlük tek kalmalı.

## Kurulum ve çalıştırma

```bash
make nb-setup     # .venv'e jupyterlab + matplotlib + itables (bir kez)
make nb           # JupyterLab başlat → http://127.0.0.1:8888
make nb-url       # çalışan sunucunun jetonlu URL'ini bas
make nb-exec      # üç notebook'u başsız çalıştır: hatasız koşuyorlar mı?
make nb-clean     # üç notebook'un çıktılarını temizle
```

> **`make nb-exec` açmak için değil.** Sunucu da tarayıcı da başlatmıyor; notebook'ları
> `/tmp` klasörüne kopyalayıp başsız çalıştırıyor ve biri hata verirse sıfırdan farklı
> bir kodla çıkıyor. Repodaki dosyaların çıktılarına dokunmuyor. Açmak için `make nb`.

**JupyterLab'in kökü repo kökü** (`NB_ROOT ?= .`), `notebooks/` değil. Böylece dosya
tarayıcısında `src/data/*.parquet` dosyaları görünüyor ve açılabiliyor. Çalışan bir
sunucu `--notebook-dir` ayarını başlangıçta sabitliyor; kökü değiştirdiysen sunucuyu
yeniden başlatmak gerekiyor (`Ctrl-C`, sonra `make nb`).

> **Not:** JupyterLab açık bir sekmeyi diskteki değişiklikle kendiliğinden tazelemiyor.
> Defteri dışarıdan güncellediysen sekmeyi yenile (F5) ya da kapatıp yeniden aç.

### Uzaktan erişim (başsız sunucu)

Bu makinede tarayıcı ve `DISPLAY` yoksa JupyterLab kendiliğinden açılmıyor; **Chrome
senin dizüstünde çalışır**, sunucuda değil. İki yol var.

**A. SSH tüneli (önerilen; jeton ağda dolaşmaz)**

```bash
# 1) sunucuda:
make nb

# 2) kendi dizüstünde, ayrı bir terminalde açık bırak (komutu make tunnel basar):
ssh -N -L 8888:127.0.0.1:8888 ubuntu@<sunucu-ip>

# 3) sunucuda jetonlu URL'i al, dizüstü tarayıcısına olduğu gibi yapıştır:
make nb-url       # → http://127.0.0.1:8888/?token=...
```

`127.0.0.1:8888` artık tünelin ucu; URL'i değiştirmen gerekmiyor.

**B. Doğrudan bağlama (tek komut, daha az güvenli)**

```bash
make nb NB_IP=0.0.0.0
# dizüstünde: http://<sunucu-ip>:8888/?token=...
```

Jeton bu durumda ağ üzerinden gidiyor ve portun güvenlik duvarında açık olması
gerekiyor. Tünel mümkünse A'yı seç.

## `data-quality-dashboard.ipynb` — doğrulama

Bölümler: **(2)** veri kaynağı ve tazelik · **(3)** hacim ve label dağılımı ·
**(4)** Problem B, `normal` sınıfında runtime kapsamı · **(5)** senaryo × feature
ayrılabilirlik ve dejenere feature uyarıları · **(6)** feature dağılımları (boxplot) ·
**(7)** window boyutu karşılaştırması · **(8)** archive kıyası · **(9)** kabul
kriterleri.

**Bölüm 7 neden boş çıkabilir:** `features.parquet` her window boyutu için aynı yola
yazılıyor, dolayısıyla karşılaştırma ancak window başına ayrı çıktı alınarak yapılabiliyor:

```bash
make features WINDOW=5s  FEATURES_OUT=data/features/features-5s.parquet
make features WINDOW=10s FEATURES_OUT=data/features/features-10s.parquet
make features WINDOW=30s FEATURES_OUT=data/features/features-30s.parquet
```

Dosya yoksa notebook bu komutları kendisi basıyor; sessizce boş grafik çizmiyor.

## `advisor-demo.ipynb` — danışan sunumu

Anlatı notebook'u. Sırasıyla: tez ne yapıyor (problem, özgün katkı, hedef mimari) →
nerede duruyoruz (faz indeksi, canlı okunuyor) → şu ana kadar ne yaptık ve neden
(FAZ 0→3, elenen alternatifler dahil) → bulgu (hacim, runtime katmanı, skorların
mekanizması) → FAZ 3.5 planı → mevcut durum → sıradaki adım ve riskler.

Sunumla ilgili iki pratik not:

- **Önce tazelik hücresine bak (§0).** `features.parquet` ham veriden sonra
  üretilmediyse uyarı çıkıyor; o durumda bütün rakamlar eski koşuya ait olur ve bunu
  sunumda belirtmek gerekir.
- **Bulgu bölümü (§4) bilerek ölçüme bağlı.** Sonuç cümleleri metne yazılmıyor, veriden
  hesaplanıyor; veri değişince cümleler de değişiyor. Böylece "skorlar yüksek, demek ki
  tespit iyi" tuzağına düşmüyor: skorun paydası normal sınıfının kendi standart sapması
  ve o sıfıra yakınsa skor şişiyor.

## `parquet-explorer.ipynb` — araç

Ham parquet dosyalarını incelemek için: `itables` ile sırala, ara, filtrele, sayfala,
CSV indir. Üç sınır:

- **Satır sınırı açık.** Tablo ilk `PREVIEW_ROWS` (1000) satırla sınırlı ve sınır
  caption'da yazıyor. itables'ın varsayılan davranışı 64KB'ı aşan tabloyu sessizce
  örneklemek; bunu kapattık (`itables.options.maxBytes = 0`), çünkü sessiz küçültme
  "veriyi gördüm" yanlış izlenim veriyor.
- **Merged dosya koşu bitince yazılıyor.** `flows.parquet` ve `events.parquet` yokken
  bölüm en yeni `.partNNNN.parquet` dosyasına düşüyor ve bunu ekrana yazıyor. Part
  dosyalarının satır sayısı yalnızca parquet footer'ından okunuyor; yüz binlerce satırı
  yüklemeye gerek kalmıyor.
- **itables JavaScript istiyor.** JS ve CSS tablo çıktısına base64 olarak gömülüyor
  (tarayıcıda internet gerekmiyor), ama JS çalışmazsa — güvensiz (untrusted) notebook,
  statik PDF — tablo gizli kalıyor. JupyterLab'de hücreyi çalıştırdığında normal
  görünüyor.

> **Dosya boyutu:** çıktılar kaydedilirse itables JS'i (~1MB) ve tablo verisi notebook'a
> giriyor. Commit'ten önce `make nb-clean` çalıştır; repodaki notebook'lar çıktısız kalsın.

## Grafik kuralları

Grafikler dataviz referans paletinin açık sürümüyle çiziliyor (`style.py`). Kategorik
renkler sabit sırada atanıyor ve döngüye sokulmuyor; palette validator'dan geçti
(slot 1+2 CVD ΔE 24,7). Heatmap tek hue'lu mavi bir sıralı ölçek kullanıyor; hücrelerdeki
sayılar tam değeri taşıdığı için renk ölçeği kırpılabiliyor. Status renkleri (yeşil,
kırmızı) asla tek başına anlam taşımıyor; her zaman simge ve etiketle birlikte geliyor.

**Bilinen sınırlar:**

- Defterler statik PNG üretiyor, tema seçilemiyor; açık zemine sabitlenmiş durumda.
- Ne figürlerde ne tablolarda emoji veya simge kullanılıyor; durum bilgisi yalnızca
  kelimeyle veriliyor (`style.status_text`).
- Dashboard'da saldırı dağılımları bütün senaryolar birleşik gösteriliyor; senaryo
  bazında ayrışma ayrılabilirlik bölümünde.
