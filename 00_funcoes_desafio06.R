# =============================================================================
# 00_funcoes_desafio06.R
#
# DATA CHALLENGE 06 -- SHARED FUNCTIONS
# Bitterlich point-sampling inventory processing.
#
# Sourced (not run directly) by 01_processar_bitterlich.R.
# =============================================================================

# -----------------------------------------------------------------------
# REUSED MODELS (fitted previously, on Stand 8's data -- see README)
# -----------------------------------------------------------------------
# Challenge 02 hypsometric model (log-log, Baskerville-corrected):
#     ln(HT) = B0 + B1 * ln(DAP)   ->   HT = FC * exp(B0 + B1*ln(DAP))
HIPSO_B0 <- 1.403490
HIPSO_B1 <- 0.688478
HIPSO_FC <- 1.001099

# Challenge 04 double-entry volume equation (Spurr):
#     V = SPURR_B0 + SPURR_B1 * (DAP^2 * HT)
SPURR_B0 <- 0.00316157
SPURR_B1 <- 0.0000363366

# -----------------------------------------------------------------------
# 1) Section area and trees/ha represented by one counted tree
# -----------------------------------------------------------------------
# g_i   = individual basal (sectional) area of tree i, in m^2, from DAP (cm)
# N_i   = how many trees/ha this ONE counted tree represents, given the
#         stand's Basal Area Factor (FAB, m^2/ha). This is the heart of
#         Bitterlich sampling: a THIN tree represents MANY trees/ha (it's
#         only counted when very close to the point), a THICK tree
#         represents FEW trees/ha (it's counted even far from the point).
area_seccional_m2 <- function(DAP_cm) {
  (pi / 40000) * DAP_cm^2
}

arvores_por_ha <- function(DAP_cm, FAB) {
  g_i <- area_seccional_m2(DAP_cm)
  FAB / g_i
}

# -----------------------------------------------------------------------
# 2) Estimated height and estimated individual volume (reused models)
# -----------------------------------------------------------------------
estimar_altura <- function(DAP_cm) {
  HIPSO_FC * exp(HIPSO_B0 + HIPSO_B1 * log(DAP_cm))
}

estimar_volume_individual <- function(DAP_cm, HT_m) {
  SPURR_B0 + SPURR_B1 * (DAP_cm^2 * HT_m)
}

# -----------------------------------------------------------------------
# 3) Process every counted tree: g_i, N_i, HT_est, V_i, and this tree's
#    contribution to the point's volume/ha (N_i * V_i)
# -----------------------------------------------------------------------
processar_arvores <- function(arvores, FAB) {
  arvores$g_i          <- area_seccional_m2(arvores$DAP_cm)
  arvores$n_arvores_ha <- arvores_por_ha(arvores$DAP_cm, FAB)
  arvores$altura_estimada_m   <- estimar_altura(arvores$DAP_cm)
  arvores$volume_individual_m3 <- estimar_volume_individual(
    arvores$DAP_cm, arvores$altura_estimada_m
  )
  arvores$vol_ha_contrib <- arvores$n_arvores_ha * arvores$volume_individual_m3
  arvores
}

# -----------------------------------------------------------------------
# 4) Per-point summary: mean DAP/height/individual volume, and volume/ha
# -----------------------------------------------------------------------
# volume_ha(point) = sum, over every tree counted AT THAT POINT, of
#                    (n_arvores_ha_i * volume_individual_i)
# A point that had NO tree counted (rare but possible at low FAB / sparse
# stands) still gets a row, with volume_ha = 0 -- it is a REAL, valid
# observation of "no basal area represented here" and must NOT be dropped,
# or the random-sample statistics below would be biased upward.
resumir_por_ponto <- function(arvores_processadas, n_pontos) {
  agregado <- aggregate(
    cbind(DAP_cm, altura_estimada_m, volume_individual_m3) ~ Ponto,
    data = arvores_processadas, FUN = mean
  )
  names(agregado) <- c("ponto", "dap_medio_cm", "altura_media_m",
                        "volume_individual_medio_m3")

  vol_ha <- aggregate(vol_ha_contrib ~ Ponto, data = arvores_processadas, FUN = sum)
  names(vol_ha) <- c("ponto", "volume_ha_m3")

  resumo <- merge(agregado, vol_ha, by = "ponto", all = TRUE)

  # add back any point with zero counted trees (all.x grid ensures this)
  todos_pontos <- data.frame(ponto = seq_len(n_pontos))
  resumo <- merge(todos_pontos, resumo, by = "ponto", all.x = TRUE)
  resumo$volume_ha_m3[is.na(resumo$volume_ha_m3)] <- 0
  # DAP/height/volume-individual means stay NA for an empty point (there is
  # no tree to average) -- that's correct, not a bug: only volume_ha_m3
  # (a sum) is defined as 0 for an empty point.

  resumo[order(resumo$ponto), ]
}

# -----------------------------------------------------------------------
# 5) Simple random sampling statistics over the n per-point volume/ha
#    values (the assignment's reference-formula table)
# -----------------------------------------------------------------------
processar_amostragem_simples <- function(volumes_ha, confianca = 0.95) {
  n      <- length(volumes_ha)
  xbar   <- mean(volumes_ha)
  var_x  <- var(volumes_ha)          # sample variance, R's var() already uses (n-1)
  sd_x   <- sqrt(var_x)
  se_x   <- sd_x / sqrt(n)

  alpha  <- 1 - confianca
  t_crit <- qt(1 - alpha / 2, df = n - 1)   # two-tailed, n-1 df

  ea     <- t_crit * se_x
  er_pct <- ea / xbar * 100

  data.frame(
    n = n,
    volume_medio_ha_m3 = xbar,
    variancia = var_x,
    desvio_padrao = sd_x,
    erro_padrao_media = se_x,
    t_critico = t_crit,
    erro_absoluto = ea,
    erro_relativo_pct = er_pct,
    ic_inferior_ha = xbar - ea,
    ic_superior_ha = xbar + ea
  )
}
