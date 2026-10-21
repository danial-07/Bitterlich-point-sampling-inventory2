# Short Report — Data Challenge 06: Bitterlich Point-Sampling Inventory

Stand 20, eucalyptus plantation. 25 sampling points, Basal Area Factor
(FAB) = 3 m²/ha, total area = 25 ha, 228 trees counted across all points.

## Results

| Estimate | Value |
|---|---|
| Mean volume/ha (x̄) | 379.98 m³/ha |
| Variance (s²) | 15,908.31 |
| Standard deviation (s) | 126.13 m³/ha |
| Standard error of the mean (Sx̄) | 25.23 m³/ha |
| t (24 df, 95%) | 2.064 |
| Absolute error (EA) | 52.06 m³/ha |
| **Relative error (ER%)** | **13.70%** |
| 95% CI for mean volume/ha | [327.91, 432.04] m³/ha |
| **Stand total volume** | **9,499.4 m³** |
| 95% CI for stand total | [8,197.8, 10,801.0] m³ |

## Is the relative error acceptable?

**Yes, 13.70% is within the range generally considered acceptable for
operational forest inventories.** The conventional benchmark in Brazilian
forestry practice is that a relative error up to ~10% is "good," and up to
~15–20% is still broadly usable for stand-level planning (volume
estimates always carry more uncertainty than, say, area estimates). At
13.70%, this inventory sits comfortably inside that commonly-accepted
range — not as tight as a well-designed fixed-area plot inventory with a
larger sample, but reasonable for 25 Bitterlich points. If a tighter
estimate were required (say, under 10%), the standard remedy is simply
more sampling points, since Sx̄ shrinks with `1/sqrt(n)` — going from 25 to
100 points would roughly halve the error, all else equal.

## Limitations of reusing Stand 8's hypsometric and volume models on Stand 20

This is the more important discussion, because it's a real methodological
compromise, not just a formality:

**The hypsometric relationship (height vs. DAP) is stand-specific.** It
reflects a stand's site quality, age, spacing, and genetic material.
Checking the actual metadata: Stand 8 is **7 years old, site class 1**,
and Stand 20 is **also 7 years old, also site class 1** — on age and site
class specifically, these two stands are well matched, which is the best
case for borrowing a model across stands and makes this particular
transfer less risky than it could have been. That is a fortunate
coincidence of which stand got paired with which, though — it is not
something the method guarantees. (For comparison, the other stand
provided alongside this one, Stand 12, is only **5 years old and site
class 2** — a meaningfully different stand, where reusing Stand 8's
curves would be a much shakier assumption than it is for Stand 20.)
Spacing (3×3 m) and clone (1501) do match across all three stands, which
also helps. The remaining risk is anything the metadata doesn't capture:
micro-site variation, management history, or genetic variation within the
same clone code.

**The volume equation carries the same risk, one layer deeper.** It was
calibrated on Stand 8's actual stem *form* (how cylindrical vs. cone-like
the trunk is), which is driven by the same factors as height (genetics,
spacing, age, site) — so wherever the two stands do differ, that
difference affects the volume equation's accuracy on top of, and
independently from, any error already introduced by the height estimate
feeding into it (since this equation uses *estimated* height, not a
measured one, as an input).

**Bottom line**: the 13.70% relative error reported above measures only
the **sampling error** — how much the mean volume/ha would vary if you
repeated the same 25-point Bitterlich sample on this same stand many
times. It does **not** capture this **model-transfer bias** (using Stand
8's curves on Stand 20's trees), which could be larger or smaller than the
sampling error itself, and — critically — doesn't show up as "error" in
the confidence interval at all, because a systematic bias shifts the
*whole* interval in one direction rather than widening it. In a real
operational setting, the correct fix would be to fit the hypsometric
relationship and volume equation directly on a (even small) cubagem sample
taken **in Stand 20 itself**, rather than borrowing Stand 8's. Until that's
done, this inventory's total volume (9,499 m³, CI [8,198, 10,801]) should
be read as "precise to within the stated sampling error, but of unverified
accuracy," rather than as an unqualified result.
