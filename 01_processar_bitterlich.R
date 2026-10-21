# =============================================================================
# 01_processar_bitterlich.R
#
# DATA CHALLENGE 06
# Process a Bitterlich point-sampling inventory: estimate height and volume
# for every counted tree (reusing the Challenge 02 hypsometric model and the
# Challenge 04 Spurr volume equation, both originally fit on Stand 8),
# compute volume/ha per sampling point, then treat the per-point values as
# a simple random sample to get the stand's mean volume/ha, its sampling
# error, and the stand's total volume with a 95% confidence interval.
#
# HOW TO USE:
#   1. Edit BITTERLICH_FILE, OUT_DIR and FUNCOES_FILE below.
#      (Works unchanged on bitterlich_talhao20.xlsx OR bitterlich_talhao12.xlsx
#       -- or any other stand following the same 3-sheet layout -- since the
#       stand's FAB, area and point count are all READ FROM THE FILE,
#       nothing is hardcoded.)
#   2. Run: Rscript 01_processar_bitterlich.R
#
# Requires: readxl (install.packages("readxl"))
# =============================================================================

# =============================================================================
# CONFIG -- edit these three lines to match your computer
# =============================================================================
BITTERLICH_FILE <- "C:/path/to/your/bitterlich_talhao20.xlsx"      # <-- change this
OUT_DIR         <- "C:/path/to/your/outputs"                       # <-- change this
FUNCOES_FILE    <- "C:/path/to/your/00_funcoes_desafio06.R"         # <-- change this
# =============================================================================

if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
library(readxl)

if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)
if (!file.exists(BITTERLICH_FILE)) stop(paste0("File not found:\n", BITTERLICH_FILE))
if (!file.exists(FUNCOES_FILE)) stop(paste0("File not found:\n", FUNCOES_FILE))

source(FUNCOES_FILE)

cat("Loading:", BITTERLICH_FILE, "\n\n")
info     <- read_excel(BITTERLICH_FILE, sheet = "Info_Talhao")
pontos   <- read_excel(BITTERLICH_FILE, sheet = "Pontos")
arvores  <- read_excel(BITTERLICH_FILE, sheet = "Arvores")

# -----------------------------------------------------------------------
# 1) Read the stand's own metadata (FAB, area, number of points) --
#    nothing about the stand is hardcoded, it all comes from Info_Talhao
# -----------------------------------------------------------------------
get_info <- function(padrao) {
  linha <- info[grepl(padrao, info$Variável), ]
  as.numeric(linha$Valor[1])
}

FAB       <- get_info("FAB")
AREA_HA   <- get_info("Área total")
N_PONTOS  <- get_info("pontos de amostragem")

cat("Stand metadata read from Info_Talhao:\n")
cat("  Basal Area Factor (FAB):", FAB, "m2/ha\n")
cat("  Total stand area:       ", AREA_HA, "ha\n")
cat("  Number of sample points:", N_PONTOS, "\n\n")

cat("Trees counted across all points:", nrow(arvores), "\n")
cat("DAP range:", round(min(arvores$DAP_cm), 1), "-",
    round(max(arvores$DAP_cm), 1), "cm\n\n")

# -----------------------------------------------------------------------
# 2) Process every counted tree: section area, trees/ha represented,
#    estimated height, estimated individual volume
# -----------------------------------------------------------------------
arvores_proc <- processar_arvores(arvores, FAB)

cat("Preview of processed trees:\n")
print(head(arvores_proc[, c("Ponto", "Arvore", "DAP_cm", "altura_estimada_m",
                             "volume_individual_m3", "n_arvores_ha")]))
cat("\n")

# Required output 1: arvores_processadas.csv
out1 <- arvores_proc[, c("Ponto", "Arvore", "DAP_cm", "altura_estimada_m",
                          "volume_individual_m3", "n_arvores_ha")]
names(out1) <- c("ponto", "arvore", "dap_cm", "altura_estimada_m",
                  "volume_individual_m3", "n_arvores_ha")
write.csv(out1, file.path(OUT_DIR, "arvores_processadas.csv"), row.names = FALSE)
cat("Saved:", file.path(OUT_DIR, "arvores_processadas.csv"), "\n\n")

# -----------------------------------------------------------------------
# 3) Per-point summary: mean DAP/height/individual-volume, and volume/ha
# -----------------------------------------------------------------------
resumo_pontos <- resumir_por_ponto(arvores_proc, N_PONTOS)

cat("=== Per-point summary ===\n")
print(resumo_pontos)
cat("\n")

n_vazios <- sum(is.na(resumo_pontos$dap_medio_cm))
if (n_vazios > 0) {
  cat("NOTE:", n_vazios, "point(s) had zero trees counted -- their",
      "volume_ha_m3 is correctly 0 and IS included in the sampling\n",
      "statistics below (dropping it would bias the mean upward).\n\n")
}

write.csv(resumo_pontos, file.path(OUT_DIR, "resumo_por_ponto.csv"), row.names = FALSE)
cat("Saved:", file.path(OUT_DIR, "resumo_por_ponto.csv"), "\n\n")

# -----------------------------------------------------------------------
# 4) Simple random sampling over the N_PONTOS volume/ha values
# -----------------------------------------------------------------------
stats_amostra <- processar_amostragem_simples(resumo_pontos$volume_ha_m3, confianca = 0.95)

cat("=== Simple random sampling statistics (volume/ha) ===\n")
print(stats_amostra)
cat("\n")

# -----------------------------------------------------------------------
# 5) Stand total volume and its confidence interval
# -----------------------------------------------------------------------
volume_total        <- stats_amostra$volume_medio_ha_m3 * AREA_HA
ic_inferior_total    <- stats_amostra$ic_inferior_ha * AREA_HA
ic_superior_total    <- stats_amostra$ic_superior_ha * AREA_HA

cat("=== Stand total (area =", AREA_HA, "ha) ===\n")
cat("Total volume:    ", round(volume_total, 2), "m3\n")
cat("95% CI:           [", round(ic_inferior_total, 2), ",",
    round(ic_superior_total, 2), "] m3\n\n")

# Required output 2: resumo_inventario.csv
resumo_inv <- data.frame(
  volume_medio_ha_m3 = stats_amostra$volume_medio_ha_m3,
  variancia           = stats_amostra$variancia,
  desvio_padrao       = stats_amostra$desvio_padrao,
  erro_padrao_media    = stats_amostra$erro_padrao_media,
  erro_absoluto        = stats_amostra$erro_absoluto,
  erro_relativo_pct    = stats_amostra$erro_relativo_pct,
  ic_inferior_ha       = stats_amostra$ic_inferior_ha,
  ic_superior_ha       = stats_amostra$ic_superior_ha,
  volume_total_talhao_m3 = volume_total,
  ic_inferior_total    = ic_inferior_total,
  ic_superior_total    = ic_superior_total
)
write.csv(resumo_inv, file.path(OUT_DIR, "resumo_inventario.csv"), row.names = FALSE)
cat("Saved:", file.path(OUT_DIR, "resumo_inventario.csv"), "\n")

# -----------------------------------------------------------------------
# 6) Quick acceptability check on the relative error (discussed in README
#    / report -- forestry inventories commonly target ER% <= 10-20%)
# -----------------------------------------------------------------------
cat("\n=== Relative error check ===\n")
cat("ER% =", round(stats_amostra$erro_relativo_pct, 2),
    "% -- typical acceptable range for forest inventories is ~10-20%.\n")

cat("\nFINISHED.\n")
