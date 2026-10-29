"""Birden çok notebook'un paylaştığı grafikler.

**Sınır:** burada yalnızca birden fazla notebook'un kullandığı grafikler var. Tek bir
notebook'a özel olanlar (boxplot'lar, window karşılaştırması, tek kurallı deney grafiği) o
notebook'un kendi içinde duruyor; orada okunabilir olmalarının belgeleme değeri var.

**Değerler burada hesaplanmıyor.** Her fonksiyon `src/validate_dataset.py` içindeki
asıl fonksiyonları çağırıyor. Bu modül yalnızca çiziyor; ölçüm mantığının ikinci bir
kopyası doğmuyor.
"""
from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D

import style

style.bootstrap()  # src/ import yolunda olsun (idempotent → import sırası önemsiz)
from style import (AXIS, BAD, GOOD, INK, INK_2, MUTED, S1, SURFACE,  # noqa: E402
                   status_fig, strip_frame)

import validate_dataset as vd  # noqa: E402
from features.extract_features import ALL_COLS, RT_COLS  # noqa: E402


def label_distribution(df, window="?"):
    """Hacim ve label dağılımı grafiği; her çubuğun kendi hedefi dikey bir
    işaretle gösterilir.

    `normal` ile senaryoların hedefleri farklı olduğu için tek bir yatay çizgi
    ikisini temsil edemez. Döner: ``(fig, overview DataFrame)``
    """
    summary = vd.summarize(df)
    target_normal = vd.TARGETS["normal_rows"]
    target_scenario = vd.TARGETS["rows_per_scenario"]

    labels = ["normal"] + summary["scenarios"]
    counts = df.label.value_counts().to_dict()
    overview = pd.DataFrame({
        "etiket": labels,
        "window sayısı": [int(counts.get(l, 0)) for l in labels],
        "hedef": [target_normal if l == "normal" else target_scenario for l in labels],
    })

    fig, ax = plt.subplots(figsize=(7.6, 3.6))
    y = list(range(len(overview)))[::-1]                  # normal en üstte
    values = overview["window sayısı"].tolist()

    ax.barh(y, values, height=0.5, color=S1, zorder=3)
    for yi, t in zip(y, overview["hedef"]):
        ax.plot([t, t], [yi - 0.3, yi + 0.3], color=INK_2, lw=2,
                solid_capstyle="butt", zorder=4)
    gap = max(values + [1]) * 0.02
    for yi, v in zip(y, values):
        ax.text(v + gap, yi, f"{v}", va="center", ha="left", color=INK_2, fontsize=8)

    span = values + list(overview["hedef"])              # dikkat: list + Series toplanır!
    ax.set_yticks(y)
    ax.set_yticklabels(overview["etiket"])
    ax.set_xlabel(f"{window} window sayısı")
    ax.set_title("Label dağılımı ve kabul eşiği")
    ax.xaxis.grid(True)
    ax.set_xlim(0, max(span) * 1.18)
    strip_frame(ax)
    ax.legend(handles=[Line2D([0], [0], color=INK_2, lw=2,
                              label=f"hedef (normal ≥ {target_normal} · senaryo ≥ {target_scenario})")],
              loc="lower right")
    fig.tight_layout()
    return fig, overview


def coverage_panel(df):
    """Problem B: `normal` sınıfında runtime coverage.

    Solda tek bir sayı (stat tile) ve hedefi, sağda runtime feature'ların normal
    satırlarda sıfırdan farklı olma oranı. Döner: ``(fig, coverage)``
    """
    coverage = vd.normal_runtime_coverage(df)
    target = vd.TARGETS["normal_runtime_coverage"]
    ok = coverage >= target

    fig, (ax_tile, ax_bar) = plt.subplots(1, 2, figsize=(9.6, 2.9),
                                         gridspec_kw={"width_ratios": [1, 2.1]})
    ax_tile.axis("off")
    ax_tile.text(0, 0.74, f"%{coverage * 100:.1f}", fontsize=38, color=INK,
                 va="center", ha="left")
    ax_tile.text(0, 0.40, "normal satırların runtime kapsamı", fontsize=9,
                 color=INK_2, va="center", ha="left")
    ax_tile.text(0, 0.26, f"hedef ≥ %{target * 100:.0f}", fontsize=8, color=MUTED,
                 va="center", ha="left")
    ax_tile.text(0, 0.08, status_fig(ok), fontsize=11, color=(GOOD if ok else BAD),
                 va="center", ha="left")

    normal = df[df.label == "normal"]
    nonzero_rate = (normal[RT_COLS].fillna(0) > 0).mean().sort_values()
    yy = list(range(len(nonzero_rate)))
    ax_bar.barh(yy, nonzero_rate.values, height=0.5, color=S1, zorder=3)
    ax_bar.axvline(target, color=INK_2, lw=2, solid_capstyle="butt", zorder=4)
    ax_bar.set_yticks(yy)
    ax_bar.set_yticklabels(nonzero_rate.index)
    ax_bar.set_xlim(0, 1)
    ax_bar.set_xticks([0, .25, .5, .75, 1])
    ax_bar.set_xticklabels(["%0", "%25", "%50", "%75", "%100"])
    ax_bar.set_xlabel("normal satırların oranı")
    ax_bar.set_title("Runtime feature'ları — normal sınıfında ne sıklıkla sıfırdan farklı?")
    ax_bar.xaxis.grid(True)
    strip_frame(ax_bar)
    ax_bar.annotate(f"kapsam eşiği %{target * 100:.0f}",
                    xy=(target, len(nonzero_rate) - 0.4), xytext=(6, 0),
                    textcoords="offset points", color=INK_2, fontsize=8,
                    va="center", ha="left")
    fig.tight_layout()
    return fig, coverage


def separability_heatmap(df):
    """Senaryo × feature separability heatmap'i; skorlar normal σ cinsinden.

    Renk ölçeği 90. yüzdeliğe kırpılıyor. Hücrelerdeki sayılar tam değeri taşıdığı
    için bu kırpma bilgi kaybettirmiyor, yalnızca threshold civarını görünür kılıyor.
    Döner: ``(fig, scores DataFrame, scenarios)``
    """
    scenarios = vd.summarize(df)["scenarios"]
    scores = (pd.DataFrame({s: vd.separability(df, s) for s in scenarios})
              .T.reindex(columns=ALL_COLS))
    finite = scores.values[np.isfinite(scores.values.astype(float))]
    vmax = max(2.0 * vd.DISCRIMINATOR_THRESHOLD,
               float(np.percentile(finite, 90)) if finite.size else 2.0)

    fig, ax = plt.subplots(figsize=(9.8, 3.2))
    im = ax.imshow(np.ma.masked_invalid(scores.values.astype(float)),
                   cmap=style.sequential_blue(), vmin=0, vmax=vmax, aspect="auto")

    ax.set_xticks(range(len(ALL_COLS)))
    ax.set_xticklabels(ALL_COLS, rotation=32, ha="right")
    ax.set_yticks(range(len(scenarios)))
    ax.set_yticklabels(scenarios)
    # Hücreler arası 2px surface gap (çizgi değil, boşluk).
    ax.set_xticks(np.arange(-.5, len(ALL_COLS), 1), minor=True)
    ax.set_yticks(np.arange(-.5, len(scenarios), 1), minor=True)
    ax.grid(which="minor", color=SURFACE, linewidth=2)
    ax.tick_params(which="minor", length=0)

    for i in range(scores.shape[0]):
        for j in range(scores.shape[1]):
            v = scores.values[i, j]
            if not np.isfinite(v):
                ax.text(j, i, "—", ha="center", va="center", color=MUTED, fontsize=8)
                continue
            r, g, b, _ = im.cmap(im.norm(min(v, vmax)))
            ink = "#ffffff" if (0.2126 * r + 0.7152 * g + 0.0722 * b) < 0.5 else INK
            ax.text(j, i, f"{v:.1f}", ha="center", va="center", fontsize=7.5,
                    color=ink,
                    fontweight="bold" if v >= vd.DISCRIMINATOR_THRESHOLD else "normal")

    cb = fig.colorbar(im, ax=ax, pad=0.015, fraction=0.03)
    cb.set_label(f"ayrılabilirlik (normal σ) · ölçek 0–{vmax:.1f}, üstü kırpık",
                 color=INK_2, fontsize=8)
    cb.outline.set_visible(False)
    cb.ax.tick_params(labelsize=7, color=AXIS)
    ax.set_title("Senaryoyu normalden ayıran feature'lar  (kalın = eşiği geçiyor)")
    fig.tight_layout()
    return fig, scores, scenarios
