# =====================================================================
# Tez derleme Makefile — KOU FBE LaTeX şablonu (kou.cls)
#
# Hedefler:
#   make            -> derle (varsayılan, artımlı): pdflatex + biber + çapraz referans
#   make force      -> kaynaklara dokunmadan zorla tam derle
#   make watch      -> kaynak değişince otomatik derle (sürekli önizleme)
#   make clean      -> yardımcı dosyaları sil (PDF kalır)
#   make cleanall   -> yardımcı dosyalar + PDF'i sil
#   make view       -> PDF'i aç (masaüstü ortamda)
#   make wordcount  -> metindeki kelime sayısı (PDF üzerinden)
#   make help       -> bu listeyi göster
#
# Gereksinimler: latexmk, pdflatex, biber, pdftotext (texlive).
# =====================================================================

MAIN      = tez
LATEXMK   = latexmk
PDFLATEX  = pdflatex -interaction=nonstopmode
PDFVIEWER = xdg-open

.PHONY: all force watch clean cleanall view wordcount help

# `make` her zaman latexmk'i çağırır. latexmk kendi artımlılığını yönetir ve
# kaynaklar güncelse hızlı döner; böylece `make` sessizce
# "Nothing to be done for 'all'" deyip hiçbir şey yapmaz durumuna düşmez ve
# kullanıcı her zaman anlamlı bir çıktı görür.
#
# (Eskiden tez.pdf bir dosya hedefi olarak tanımlıydı. PDF kaynaklardan yeni
# olduğu sürece make haklı olarak hiçbir şey yapmıyordu; bu da "derleyemedim"
# izlenimi veriyordu.)
all:
	$(LATEXMK) -f -pdf -pdflatex="$(PDFLATEX)" $(MAIN).tex; \
	test -f $(MAIN).pdf

# Kaynaklara dokunmadan zorla tam derleme. Şüpheli bir .aux/.bbl/.toc sonrası
# ya da "gerçekten baştan derlensin" istendiğinde kullanılır.
force:
	$(LATEXMK) -f -g -pdf -pdflatex="$(PDFLATEX)" $(MAIN).tex; \
	test -f $(MAIN).pdf

watch:
	$(LATEXMK) -f -pdf -pdflatex="$(PDFLATEX)" -pvc $(MAIN).tex

clean:
	$(LATEXMK) -c

cleanall:
	$(LATEXMK) -C

view: all
	$(PDFVIEWER) $(MAIN).pdf

wordcount: all
	@pdftotext $(MAIN).pdf - 2>/dev/null | wc -w

help:
	@echo "Kullanım:"
	@echo "  make            derle (artımlı; güncelse hızlı döner)"
	@echo "  make force      zorla tam derle"
	@echo "  make watch      kaynak değişince otomatik derle"
	@echo "  make clean      yardımcı dosyaları sil (PDF kalır)"
	@echo "  make cleanall   yardımcı dosyalar + PDF'i sil"
	@echo "  make view       PDF'i aç"
	@echo "  make wordcount  kelime sayısı"
