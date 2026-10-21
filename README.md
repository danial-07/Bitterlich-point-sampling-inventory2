# Data Challenge 06 — Bitterlich Point-Sampling Inventory

Stand 20, eucalyptus plantation, inventoried by **Bitterlich sampling**
(angle-count / point sampling) instead of fixed-area plots.

```
desafio-06-bitterlich/
├── data/
│   └── bitterlich_talhao20.xlsx   (sheets: Info_Talhao, Pontos, Arvores)
├── scripts/
│   ├── 00_funcoes_desafio06.R     # shared functions
│   └── 01_processar_bitterlich.R  # full pipeline, produces all 3 outputs
├── outputs/
│   ├── arvores_processadas.csv
│   ├── resumo_por_ponto.csv
│   ├── resumo_inventario.csv
│   └── *_PYTHON_REFERENCE.csv     # Python-validated numbers to check against
├── report/
│   └── short_report_desafio06.md
└── README.md   (this file)
```

## What's different about this challenge

Every previous challenge used **fixed-area plots**: walk a known patch of
ground, measure every tree in it. Bitterlich sampling instead stands at a
**point** and, through an angle gauge, counts only the trees whose trunk
*looks* wide enough relative to how far away it is — a tree twice as far
away needs to be twice as wide to still "count." The practical effect: a
thin tree only gets counted when it's very close to the point (so it
represents **few** hectares' worth of area, i.e. **many** trees/ha), while
a thick tree gets counted even from far away (so it represents **many**
hectares, i.e. **few** trees/ha). The `Arvores` sheet already gives you the
simulated outcome of that counting process — which trees were counted at
each point, with their DAP and distance — so the R script doesn't simulate
the angle gauge itself, it starts from the count.

## Formulas used (exact, as specified in the assignment)

**Section area and trees/ha represented by each counted tree:**
```
g_i = (pi/40000) * DAP_i^2        (individual basal area, m^2)
N_i = FAB / g_i                   (trees/ha this tree represents)
```
`FAB` (Fator de Área Basal / Basal Area Factor) is read directly from the
`Info_Talhao` sheet — **3 m²/ha** for Stand 20.

**Height and individual volume (reused models — see "Assumptions" below):**
```
HT_i = FC * exp(B0 + B1 * ln(DAP_i))                  (Challenge 02 hypsometric model)
V_i  = SPURR_B0 + SPURR_B1 * (DAP_i^2 * HT_i)         (Challenge 04 Spurr volume equation)
```

**Volume/ha represented by one sampling point:**
```
volume_ha(point) = sum over all trees counted at that point of (N_i * V_i)
```

**Simple random sampling, over the N (=25 for Stand 20) per-point volume/ha
values:**
```
x̄   = mean(volume_ha)
s²  = variance(volume_ha)                 (n-1 denominator)
s   = sqrt(s²)
Sx̄  = s / sqrt(n)
EA  = t(n-1, 0.025 two-tailed) * Sx̄
ER% = EA / x̄ * 100
CI  = x̄ ± EA
```
Stand total volume and its CI = (x̄, x̄±EA) × stand area (ha).

## Assumptions adopted (reusing Stand 8's models on Stand 20 — honestly stated)

Per the assignment, Stand 20's Bitterlich data only records DAP — not
height, and obviously not the detailed cubagem needed to fit a fresh
volume equation from scratch. So, exactly as instructed:

- **Height** is estimated with the **Challenge 02 log-log hypsometric
  model**, refit here directly from the original Stand 8 measured-height
  data: `ln(HT) = 1.403490 + 0.688478 * ln(DAP)`, Baskerville-corrected
  with `FC = 1.001099`.
- **Individual volume** is estimated with the **Challenge 04 Spurr
  double-entry equation**, refit here directly from the original 36-tree
  Stand 8 cubagem data: `V = 0.00316157 + 0.0000363366 * (DAP² * HT)`
  (R² = 0.9887 on Stand 8's own calibration data).

**Both of these are Stand-8-specific models being applied, unmodified, to
a different stand (Stand 20).** That is a real methodological limitation,
not a detail to gloss over — it's discussed explicitly in the short report
(the assignment's own discussion question #9 asks for exactly this).

Edit `HIPSO_B0`/`HIPSO_B1`/`HIPSO_FC`/`SPURR_B0`/`SPURR_B1` at the top of
`00_funcoes_desafio06.R` if your own Challenge 02/04 coefficients differ
from these.

## Handling an empty point

If a sampling point happens to have **zero** trees counted (can happen
with a low FAB in a sparse stand), it is **not dropped** — it is kept as a
point with `volume_ha_m3 = 0`. Treating it as a true zero observation
(rather than deleting the row) is essential: the whole point of simple
random sampling is that every point gets an equal, honest chance to pull
the mean down as well as up. Stand 20's actual data happens to have a
tree counted at all 25 points, so this case doesn't arise here, but the
script handles it correctly regardless (see `resumir_por_ponto()` in
`00_funcoes_desafio06.R`).

## How to run

Edit the `CONFIG` block at the top of `01_processar_bitterlich.R` (3
paths), then:
```r
Rscript 01_processar_bitterlich.R
```
The same script works unchanged on `bitterlich_talhao12.xlsx` (or any
other stand with the same 3-sheet layout) — FAB, area, and point count are
all read from that file's own `Info_Talhao` sheet, nothing is hardcoded to
Stand 20.

## Output files (as required by the assignment)

| File | Content |
|---|---|
| `arvores_processadas.csv` | ponto, arvore, dap_cm, altura_estimada_m, volume_individual_m3, n_arvores_ha |
| `resumo_por_ponto.csv` | ponto, dap_medio_cm, altura_media_m, volume_individual_medio_m3, volume_ha_m3 |
| `resumo_inventario.csv` | volume_medio_ha_m3, variancia, desvio_padrao, erro_padrao_media, erro_absoluto, erro_relativo_pct, ic_inferior_ha, ic_superior_ha, volume_total_talhao_m3, ic_inferior_total, ic_superior_total |
