# 01_san_diego_temperature.R
# Question: how has San Diego's average temperature changed since 1940?
# Uses annual averages, a linear trend, a before/after comparison,
# and separate summer and winter trends.

source("00_load_and_clean.R")

# ---- 1. Annual average temperature ----
# aggregate() leaves out rows where TAVG is missing, which is fine here
# because every year still has at least 362 valid days.

annual <- aggregate(TAVG ~ year, data = daily, FUN = mean)
days_used <- aggregate(TAVG ~ year, data = daily, FUN = length)
cat("\nFewest valid days in any year:", min(days_used$TAVG), "\n")

cat("\nAnnual average temperature (C), first and last 3 years:\n")
print(rbind(head(annual, 3), tail(annual, 3)))
cat("\nWarmest year:", annual$year[which.max(annual$TAVG)],
    "at", round(max(annual$TAVG), 2), "C\n")
cat("Coolest year:", annual$year[which.min(annual$TAVG)],
    "at", round(min(annual$TAVG), 2), "C\n")

# ---- 2. Linear trend ----
# Center the year so the intercept means "the average in the middle year".

annual$year_c <- annual$year - mean(annual$year)
trend_fit <- lm(TAVG ~ year_c, data = annual)
print(summary(trend_fit))

slope_per_year <- coef(trend_fit)["year_c"]
ci <- confint(trend_fit)["year_c", ]
cat("\nTrend:", round(slope_per_year * 10, 3), "C per decade\n")
cat("95% confidence interval:", round(ci[1] * 10, 3), "to",
    round(ci[2] * 10, 3), "C per decade\n")
cat("Total change over", nrow(annual), "years:",
    round(slope_per_year * (nrow(annual) - 1), 2), "C\n")

# ---- 3. A caution about the p-value ----
# A regression assumes the errors are independent. For yearly temperature
# they usually are not: a warm year tends to be followed by another warm
# year. Check by correlating each residual with the one before it.

res <- residuals(trend_fit)
lag1 <- acf(res, plot = FALSE)$acf[2]
cat("\nLag 1 autocorrelation of residuals:", round(lag1, 2), "\n")
cat("If this is well above 0, the p-value and confidence interval above\n")
cat("are probably too optimistic.\n")

# ---- 4. Early period compared to recent period ----

early <- annual$TAVG[annual$year <= 1969]
recent <- annual$TAVG[annual$year >= 1996]
cat("\nAverage 1940 to 1969:", round(mean(early), 2), "C\n")
cat("Average 1996 to 2025:", round(mean(recent), 2), "C\n")
cat("Difference:", round(mean(recent) - mean(early), 2), "C\n")
print(t.test(recent, early))

# ---- 5. Summer and winter separately ----
# Summer = Jun, Jul, Aug. Winter = Dec, Jan, Feb, where December counts
# toward the following year's winter. Seasons with fewer than 80 days of
# data are dropped (this removes the partial winters at each end).

summer <- daily[daily$month %in% 6:8, ]
summer_mean <- aggregate(TAVG ~ year, data = summer, FUN = mean)
summer_n <- aggregate(TAVG ~ year, data = summer, FUN = length)
summer_mean <- summer_mean[summer_n$TAVG >= 80, ]

daily$winter_year <- daily$year + (daily$month == 12)
winter <- daily[daily$month %in% c(12, 1, 2), ]
winter_mean <- aggregate(TAVG ~ winter_year, data = winter, FUN = mean)
winter_n <- aggregate(TAVG ~ winter_year, data = winter, FUN = length)
winter_mean <- winter_mean[winter_n$TAVG >= 80, ]
names(winter_mean)[1] <- "year"

# Same steps for both seasons, so put them in a function
trend_per_decade <- function(season_data) {
  fit <- lm(TAVG ~ I(year - mean(year)), data = season_data)
  c(per_decade = unname(coef(fit)[2] * 10),
    p_value = summary(fit)$coefficients[2, 4])
}

cat("\nSummer trend:\n")
print(round(trend_per_decade(summer_mean), 3))
cat("Winter trend:\n")
print(round(trend_per_decade(winter_mean), 3))

# ---- 6. Plots ----

png("figures/annual_temperature.png", width = 900, height = 550, res = 120)
plot(annual$year, annual$TAVG, type = "b", pch = 16, col = "gray40",
     xlab = "Year", ylab = "Average temperature (C)",
     main = "San Diego annual average temperature, 1940 to 2025")
abline(lm(TAVG ~ year, data = annual), col = "red", lwd = 2)
legend("topleft", legend = c("Annual average", "Linear trend"),
       col = c("gray40", "red"), pch = c(16, NA), lty = c(1, 1),
       lwd = c(1, 2), bty = "n")
dev.off()

png("figures/summer_vs_winter.png", width = 900, height = 550, res = 120)
par(mfrow = c(1, 2))
plot(summer_mean$year, summer_mean$TAVG, pch = 16, col = "firebrick",
     xlab = "Year", ylab = "Average temperature (C)", main = "Summer (Jun to Aug)")
abline(lm(TAVG ~ year, data = summer_mean), lwd = 2)
plot(winter_mean$year, winter_mean$TAVG, pch = 16, col = "steelblue",
     xlab = "Year", ylab = "Average temperature (C)", main = "Winter (Dec to Feb)")
abline(lm(TAVG ~ year, data = winter_mean), lwd = 2)
dev.off()

cat("\nSaved plots to the figures folder.\n")
