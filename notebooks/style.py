"""Notebook'ların ortak görünüm katmanı: palette, tema, status metni ve repo kökü.

**Neden ayrı bir modül?** Üç notebook de aynı palette'i, aynı rcParams ayarlarını ve aynı
repo kökü aramasını kullanıyor. Bunları her notebook'ta yeniden yazmak, `ALL_COLS` veya
`TARGETS`'ı her notebook'ta yeniden yazmak gibi bir hata olurdu: iki kopya zamanla ayrışır
ve doğrulanmış palette sessizce bozulur.

**Ölçüm mantığı burada değil.** O `src/validate_dataset.py` ve
`src/features/extract_features.py` içinde. Bu modül yalnızca görünüm katmanı.

Her notebook'un ilk hücresinde şöyle kullanılıyor::

    import style
    REPO = style.bootstrap()      # repo kökü + src/ import yolunda
    style.apply_theme()
"""
from __future__ import annotations

import sys
from pathlib import Path

# --- Palette (dataviz referans paleti, açık zemin) ---------------------
# Kategorik renkler sabit sırada atanır, asla döngüye sokulmaz. Doğrulandı:
# slot 1+2 CVD ΔE 24,7 · slot 1+2+3 ΔE 9,2 (validator, light mode).
SURFACE = "#fcfcfb"                       # grafik zemini
INK = "#0b0b0b"                           # birincil metin
INK_2 = "#52514e"                         # ikincil metin
MUTED = "#898781"                         # eksen ve etiketler
GRID = "#e1e0d9"                          # kılavuz çizgisi (saç teli)
AXIS = "#c3c2b7"                          # taban çizgisi
S1, S2, S3 = "#2a78d6", "#eb6834", "#1baf7a"   # kategorik slot 1-3
GOOD, BAD = "#0ca30c", "#d03b3b"               # status — yanındaki etiketle birlikte

#: Sıralı tek hue: mavi, açıktan koyuya (heatmap / büyüklük ölçeği).
BLUE_STEPS = ["#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7",
              "#3987e5", "#2a78d6", "#256abf", "#1c5cab", "#184f95", "#104281",
              "#0d366b"]


def sequential_blue():
    """Heatmap ve büyüklük ölçekleri için tek hue'lu mavi colormap.

    NaN değerler zemin rengiyle çizilir, böylece boş hücreler veri gibi görünmez.
    """
    from matplotlib.colors import LinearSegmentedColormap

    cmap = LinearSegmentedColormap.from_list("seq_blue", BLUE_STEPS)
    cmap.set_bad(SURFACE)
    return cmap


def apply_theme() -> None:
    """matplotlib rcParams ayarlarını yapar. Defter başına bir kez çağrılır."""
    import matplotlib as mpl

    mpl.rcParams.update({
        "figure.facecolor": SURFACE, "axes.facecolor": SURFACE,
        "savefig.facecolor": SURFACE,
        "font.family": "sans-serif", "font.size": 9,
        "text.color": INK, "axes.labelcolor": INK_2, "axes.titlecolor": INK,
        "axes.edgecolor": AXIS, "axes.linewidth": 0.8, "axes.titlesize": 10,
        "xtick.color": MUTED, "ytick.color": MUTED,
        "xtick.labelsize": 8, "ytick.labelsize": 8,
        "grid.color": GRID, "grid.linewidth": 0.6, "grid.linestyle": "-",
        "legend.frameon": False, "legend.fontsize": 8, "figure.dpi": 110,
    })


def strip_frame(ax, axes=("top", "right", "left")) -> None:
    """Saç teli kalınlığında çerçeve: gereksiz kenarlıkları kaldırır ve
    kılavuz çizgilerini çizimlerin arkasına atar."""
    for side in axes:
        ax.spines[side].set_visible(False)
    ax.set_axisbelow(True)


def status_text(ok, passed="geçti", failed="kaldı") -> str:
    """Status metni. Yalnızca kelime döner; emoji veya simge kullanmaz.

    Renk tek başına anlam taşımıyor: figürlerde bu metin her zaman yanındaki sayı
    ve hedefle birlikte okunuyor. Metinler resmî dursun diye simge kullanılmıyor.
    """
    return passed if ok else failed


#: Figürlerde de aynı metin kullanılıyor (ayrı bir simge kümesi yok).
status_fig = status_text


def repo_root() -> Path:
    """Çalışma dizininden repo kökünü bulur.

    JupyterLab de nbconvert de kernel'i notebook'un kendi dizininde çalıştırıyor, yani
    `notebooks/` içinde. Yine de kökten çalıştırılma ihtimaline karşı yukarı doğru
    bakılıyor.
    """
    here = Path.cwd().resolve()
    for candidate in (here, here.parent, here.parent.parent):
        if (candidate / "src" / "validate_dataset.py").is_file():
            return candidate
    raise FileNotFoundError(f"repo kökü bulunamadı (cwd={here})")


def bootstrap() -> Path:
    """Repo kökünü bulur, `src/` klasörünü import yoluna ekler ve kökü döner."""
    root = repo_root()
    src = str(root / "src")
    if src not in sys.path:
        sys.path.insert(0, src)
    return root
