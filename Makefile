# =====================================================================
# CloudMon — kök Makefile
#
# Hedefler:
#   make run        -> CloudMon pipeline'ı baştan sona çalıştır
#   make setup      -> Python sanal ortamını kur ve bağımlılıkları yükle
#   make dashboard  -> Gerçek zamanlı izleme panosunu başlat
#   make clean      -> Üretilmiş çıktıları (figures, reports) temizle
#   make tez        -> Tezi derle (LaTeX → PDF)
#   make tez-clean  -> Tez derleme kalıntılarını temizle
#   make tez-force  -> Tezi zorla baştan derle
#   make figures    -> cloudmon çıktılarını tez resimlerine kopyala
#   make help       -> Bu listeyi göster
#
# Gereksinimler:
#   run/setup/dashboard: Python 3.9+
#   tez: latexmk, pdflatex, biber (TeX Live)
# =====================================================================

.DEFAULT_GOAL := help

CLOUDMON    := cloudmon
TEZ_DIR     := kou-fbe-latex-tez
RESIMLER    := $(TEZ_DIR)/resimler
VENV        := $(CLOUDMON)/venv
PY          := $(VENV)/bin/python

.PHONY: help run setup dashboard clean tez tez-clean tez-force figures

help:
	@echo ""
	@echo "CloudMon — Bulut Altyapısı Proaktif İzleme Sistemi"
	@echo "====================================================="
	@echo "  make setup      -> sanal ortam kur + bağımlılıkları yükle"
	@echo "  make run        -> tüm pipeline'ı çalıştır (6 adım)"
	@echo "  make dashboard  -> gerçek zamanlı izleme panosunu başlat"
	@echo "  make clean      -> üretilmiş grafikler ve raporları temizle"
	@echo ""
	@echo "Tez:"
	@echo "  make tez        -> LaTeX tezi derle (PDF)"
	@echo "  make tez-force  -> zorla baştan derle"
	@echo "  make tez-clean  -> tez derleme geçici dosyalarını sil"
	@echo "  make figures    -> CloudMon çıktılarını tez klasörüne kopyala"
	@echo ""

# ── CloudMon pipeline ──────────────────────────────────────────────

setup:
	@echo "→ Sanal ortam oluşturuluyor: $(VENV)"
	python3 -m venv $(VENV)
	$(PY) -m pip install --upgrade pip
	$(PY) -m pip install -r $(CLOUDMON)/requirements.txt
	@echo "→ Kurulum tamamlandı. Çalıştırmak için: make run"

run:
	@echo "→ CloudMon pipeline başlatılıyor..."
	$(PY) $(CLOUDMON)/main.py

dashboard:
	@echo "→ Dashboard başlatılıyor (http://localhost:8050)"
	$(PY) $(CLOUDMON)/dashboard.py

clean:
	@echo "→ Üretilmiş grafikler temizleniyor (veri ve kod korunuyor)"
	rm -f $(CLOUDMON)/results/figures/*.png
	rm -f $(CLOUDMON)/results/reports/capacity_results.json
	rm -f $(CLOUDMON)/results/reports/recommendations.json
	rm -f $(CLOUDMON)/results/reports/recommendations.txt
	rm -f $(CLOUDMON)/results/reports/shap_*.csv
	rm -f $(CLOUDMON)/data/processed/*.csv
	@echo "→ Temizlendi."

# ── Tez derlemesi ──────────────────────────────────────────────────

tez:
	$(MAKE) -C $(TEZ_DIR) all

tez-force:
	$(MAKE) -C $(TEZ_DIR) force

tez-clean:
	$(MAKE) -C $(TEZ_DIR) clean

# Cloudmon pipeline çıktılarını tez resimler klasörüne kopyalar.
# Her `make run` sonrası güncel şekilleri teze aktarmak için kullan.
figures:
	@echo "→ CloudMon şekilleri teze kopyalanıyor: $(RESIMLER)/"
	cp $(CLOUDMON)/results/figures/*.png $(RESIMLER)/
	@echo "→ $(shell ls $(CLOUDMON)/results/figures/*.png 2>/dev/null | wc -l) şekil kopyalandı."
