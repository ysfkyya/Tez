# =====================================================================
# k8s-anomaly — kök Makefile
#
# Toplama hattının asıl Makefile'ı src/Makefile'dır. Buradaki veri
# hedefleri oraya DEVREDER (kopyalamaz), dashboard'un kendi hedefleri burada.
#
# Hedefler:
#   make nb-setup    -> .venv'e dashboard bağımlılıklarını kur (jupyterlab, matplotlib, itables)
#   make nb          -> JupyterLab başlat
#   make nb-url      -> çalışan sunucunun jetonlu URL'ini bas
#   make tunnel      -> uzaktan erişim için SSH tünel komutunu bas
#   make nb-exec     -> notebook'u başsız çalıştır (kaynağı DEĞİŞTİRMEZ)
#   make nb-clean    -> notebook çıktılarını temizle
#   make features    -> [src] özellik çıkarımı (WINDOW=10s)
#   make validate    -> [src] FAZ 3.5 kabul kriterleri
#   make collect     -> [src] uçtan uca etiketli toplama
#   make setup       -> [src] venv + toplama bağımlılıkları
#   make clean       -> notebook çıktılarını temizle (veriye DOKUNMAZ)
#   make clean-data  -> [src] toplanan veriyi sil (YIKICI — dikkat)
#
# Değişkenler (örn: make nb NB_IP=0.0.0.0 NB_PORT=8888)
# =====================================================================

.DEFAULT_GOAL := help

VENV        ?= .venv
PY          := $(VENV)/bin/python
SRC         := src
NB_DIR      := notebooks
NOTEBOOKS   := $(NB_DIR)/data-quality-dashboard.ipynb \
               $(NB_DIR)/parquet-explorer.ipynb \
               $(NB_DIR)/advisor-demo.ipynb \
               $(NB_DIR)/advisor-demo-2.ipynb
# JupyterLab'in file browser kökü. Repo kökü seçildi ki src/data/*.parquet
# tarayıcıdan da görünüp açılabilsin (notebooks/ seçilseydi görünmezdi).
NB_ROOT     ?= .
# Paylaşılabilir çıktılar (HTML/PDF): repoya girmez.
NB_OUT      ?= out
# Varsayılan olarak danışman sunumu; başkası için: make nb-pdf PDF_NB=notebooks/...
PDF_NB      ?= $(NB_DIR)/advisor-demo-2.ipynb
# Kod hücrelerini gizle (paylaşılan kopya okunur olsun); PDF_FLAGS= ile kapatılır.
PDF_FLAGS   ?= --no-input
# Paylaşım çıktısı her zaman koşularak üretilir; notebook dosyasında kayıtlı
# eski çıktılar kullanılmaz.
PDF_BASE    := $(basename $(notdir $(PDF_NB)))
PDF_RUN     := $(NB_OUT)/$(PDF_BASE).executed.ipynb
# `paylasim-disi` etiketli hücreler (altyapı/kurulum) paylaşılan kopyaya girmez.
PDF_TAGS    ?= --TagRemovePreprocessor.enabled=True --TagRemovePreprocessor.remove_cell_tags=paylasim-disi
NB_IP       ?= 127.0.0.1
NB_PORT     ?= 8888
NB_EXEC_DIR ?= /tmp

# --- src/Makefile'a geçirilen değişkenler -----------------------------
# DİKKAT: bu yollar src/ dizinine görelidir; src/Makefile aynı adları kullanır.
# Roadmap FAZ 3.5 ön kararı birincil pencere 10 sn (kabul kriterini karşılayan
# en kaba pencere) — bu yüzden src'nin 30 sn varsayılanını buradan geçersiz
# kılıyoruz. Pencere karşılaştırması için ayrı çıktı ver:
#   make features WINDOW=5s  FEATURES_OUT=data/features/features-5s.parquet
#   make features WINDOW=30s FEATURES_OUT=data/features/features-30s.parquet
WINDOW      ?= 10s
NS          ?= demo
FEATURES_OUT ?= data/features/features.parquet

.PHONY: help setup nb-setup nb nb-url tunnel nb-exec nb-clean nb-html nb-pdf nb-pdf-setup

$(NB_OUT):
	@mkdir -p $(NB_OUT) features validate collect clean clean-data

help:
	@echo "Dashboard:"
	@echo "  make nb-setup    -> .venv'e dashboard bağımlılıklarını kur"
	@echo "  make nb          -> JupyterLab başlat ($(NB_IP):$(NB_PORT), kök: $(NB_ROOT))"
	@echo "  make nb-url      -> çalışan sunucunun jetonlu URL'ini bas"
	@echo "  make tunnel      -> uzaktan erişim için SSH tünel komutunu bas"
	@echo "  make nb-exec     -> notebook'u başsız çalıştır (doğrulama)"
	@echo "  make nb-clean    -> notebook çıktılarını temizle"
	@echo ""
	@echo "Paylaşım (PDF_NB=$(PDF_NB)):"
	@echo "  make nb-html     -> tek dosya HTML (kurulum gerekmez)"
	@echo "  make nb-pdf      -> PDF (Chromium; önce make nb-pdf-setup)"
	@echo "  make nb-pdf-setup-> playwright + chromium kur (~150MB)"
	@echo ""
	@echo "Veri (src/Makefile'a devreder):"
	@echo "  make setup       -> venv + toplama bağımlılıkları"
	@echo "  make features    -> özellik çıkarımı (WINDOW=$(WINDOW), NS=$(NS))"
	@echo "  make validate    -> FAZ 3.5 kabul kriterleri"
	@echo "  make collect     -> uçtan uca etiketli toplama"
	@echo "  make clean-data  -> toplanan veriyi sil (YIKICI)"
	@echo ""
	@echo "Uzaktan erişim: bu makinede tarayıcı yoksa"
	@echo "  1) burada  : make nb"
	@echo "  2) dizüstünde: make tunnel   (bastığı komutu çalıştır)"
	@echo "  3) burada  : make nb-url     (URL'i dizüstü tarayıcısına yapıştır)"

# --- Pano -------------------------------------------------------------

nb-setup:
	$(PY) -m pip install -r $(NB_DIR)/requirements.txt

# --no-browser: bu makinede tarayıcı yok (başsız sunucu). Jetonlu URL basılır;
# `make nb-url` ile tekrar alınır. Token'ı ağa saçmamak için varsayılan bağlama
# 127.0.0.1'dir — erişim SSH tüneliyle (make tunnel) verilir.
nb:
	$(PY) -m jupyterlab --no-browser --ip=$(NB_IP) --port=$(NB_PORT) \
	    --notebook-dir=$(NB_ROOT)

# Çalışan sunucunun jetonlu URL'ini basar. Dizüstünde tünel açtıysan URL'i
# OLDUĞU GİBİ yapıştırabilirsin (127.0.0.1 tünelin ucudur).
# Birden fazla sunucu çalışıyorsa HEPSİNİ basar — sessizce birini seçmez.
nb-url:
	@out="$$($(PY) -m jupyter server list 2>/dev/null | grep 'http')" ; \
	if [ -z "$$out" ]; then \
	    echo "çalışan sunucu yok — önce: make nb" ; \
	else \
	    echo "$$out" ; \
	    if [ "$$(echo "$$out" | wc -l)" -gt 1 ]; then \
	        echo "⚠️  Birden fazla sunucu var. Başlattığın portu kullan (varsayılan $(NB_PORT))." ; \
	    fi ; \
	fi

# Bu makineye SSH ile geliniyorsa, bu komutu KENDİ DİZÜSTÜNDE çalıştır:
# 8888 numaralı yerel port, sunucudaki JupyterLab'e yönlenir.
tunnel:
	@echo "ssh -N -L $(NB_PORT):127.0.0.1:$(NB_PORT) $$(whoami)@$$(hostname -I | awk '{print $$1}')"

# Başsız çalıştırma — notebook'ların gerçekten koşturulabildiğinin kanıtı.
# Çıktılar /tmp'ye yazılır, repodaki notebook'ların çıktıları ELLENMEZ (git diff temiz kalır).
# Üçünü de gezer; biri patlarsa hedef sıfırdan farklı çıkar.
nb-exec:
	@for nb in $(NOTEBOOKS); do \
	    echo "→ $$nb"; \
	    $(PY) -m nbconvert --to notebook --execute \
	        --output-dir $(NB_EXEC_DIR) \
	        --output "$$(basename $$nb .ipynb).executed.ipynb" "$$nb" || exit 1; \
	done
	@echo "→ çıktılar: $(NB_EXEC_DIR)/*.executed.ipynb"

nb-clean:
	@for nb in $(NOTEBOOKS); do $(PY) -m nbconvert --clear-output --inplace "$$nb"; done
	@echo "→ notebook'ların çıktıları temizlendi"

# --- Paylaşılabilir çıktı (HTML / PDF) --------------------------------
# İki adım: (1) notebook koşulur, (2) koşulmuş hâli dönüştürülür.
# Neden tek adım değil: `paylasim-disi` etiketli hücreleri çıkaran preprocessor,
# tek adımda koşudan ÖNCE çalışıp kurulum hücresini siliyor ve notebook çöküyor.
# İki adımda ayrıca koşulmuş ara dosya incelenebilir hâlde kalıyor.
#
# nb-html: hiçbir şey kurmadan çalışır; grafikler dosyaya gömülür. Tek dosya
# HTML'i dizüstüne indirip tarayıcıdan Ctrl+P ile de PDF'e çevirebilirsin.
nb-html: | $(NB_OUT)
	$(PY) -m nbconvert --to notebook --execute \
	    --output-dir $(NB_OUT) --output $(PDF_BASE).executed.ipynb $(PDF_NB)
	$(PY) -m nbconvert --to html $(PDF_FLAGS) $(PDF_TAGS) \
	    --output-dir $(NB_OUT) --output $(PDF_BASE).html $(PDF_RUN)
	@echo "→ $(NB_OUT)/$(PDF_BASE).html"

# Chromium ile gerçek PDF. Önce bir kez: make nb-pdf-setup
# LaTeX yolu kullanılmıyor: bu makinede pandoc ve xelatex yok, ayrıca Türkçe
# karakterler için ek ayar gerektirirdi.
nb-pdf: | $(NB_OUT)
	$(PY) -m nbconvert --to notebook --execute \
	    --output-dir $(NB_OUT) --output $(PDF_BASE).executed.ipynb $(PDF_NB)
	$(PY) -m nbconvert --to webpdf $(PDF_FLAGS) $(PDF_TAGS) \
	    --output-dir $(NB_OUT) --output $(PDF_BASE).pdf $(PDF_RUN)
	@echo "→ $(NB_OUT)/$(PDF_BASE).pdf"

nb-pdf-setup:
	$(PY) -m pip install playwright
	$(PY) -m playwright install chromium

# --- Veri (src/Makefile'a devreder) -----------------------------------

setup:
	$(MAKE) -C $(SRC) setup

features:
	$(MAKE) -C $(SRC) features WINDOW=$(WINDOW) NS=$(NS) FEATURES_OUT=$(FEATURES_OUT)

validate:
	$(MAKE) -C $(SRC) validate WINDOW=$(WINDOW) FEATURES_OUT=$(FEATURES_OUT)

collect:
	$(MAKE) -C $(SRC) collect

# Pano hedefleri dışında bir şey silmez.
clean: nb-clean

# YIKICI: toplanan ham veriyi ve etiketleri siler.
clean-data:
	$(MAKE) -C $(SRC) clean
