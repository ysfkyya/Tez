# Yüksek Lisans Tezi — Yusuf KAYA

**Konu:** Bulut Platformlarında Log ve Metrik Korelasyonuna Dayalı Yapay Zekâ Destekli Proaktif Sağlık ve Kapasite Yönetimi

**Danışman:** Doç. Dr. Hakan GÜNDÜZ — Kocaeli Üniversitesi, Yazılım Mühendisliği

---

## Repo Yapısı

```
cloudmon/          → Tez uygulaması (OpenStack proaktif izleme sistemi)
kou-fbe-latex-tez/ → LaTeX tez dosyaları (KOU FBE formatı)
referanslar/       → Literatür notları
```

## CloudMon

OpenStack bulut platformu için proaktif sağlık ve kapasite izleme sistemi.

**Özellikler:**
- 4 aşamalı log analiz pipeline (parse → aggregation → anomali → ön-arıza örüntüsü)
- 42 ML modeli ile kaynak kullanım tahmini (vCPU, Bellek, Disk; 24s/72s ufuk)
- SHAP ile model yorumlanabilirliği
- LLM destekli operasyonel öneri motoru (Claude + GPT-4o)

**Çalıştırmak için:**

```bash
cd cloudmon
pip install -r requirements.txt
python main.py
```

## Tez

`kou-fbe-latex-tez/` dizini, KOU Fen Bilimleri Enstitüsü formatında LaTeX tez şablonunu içerir.

**Gereksinim (TeX Live):**
```bash
sudo apt-get install -y texlive-full biber
```

**Derlemek için:**
```bash
make tez          # kök dizinden
# veya
cd kou-fbe-latex-tez && make
```

`make tez` komutu tüm bölümleri (`giris.tex`, `genelbilgiler.tex`, `malzemeveyontem.tex`, `bulgular.tex`, `sonuclar.tex`) birleştirip `tez.pdf` üretir.
