# 02_san_diego_rainfall.R
# Question: how much does San Diego's rainfall vary from year to year,
# and is there a trend?
# Rain years run July to June, because the wet season crosses New Year.
# A calendar year would split one winter's storms into two different years.

source("00_load_and_clean.R")

# ---- 1. Rain year totals ----

daily$rain_year <- ifelse(daily$month >= 7, daily$year + 1, daily$year)

rain <- aggregate(PRCP ~ rain_year, data = daily, FUN = sum)
rain_days <- aggregate(PRCP ~ rain_year, data = daily, FUN = length)

# Keep only full rain years. The first (1940) and last (2026) are partial.
# 1947 is kept even though 3 days in April have no row, so its total may
# be slightly low.
rain <- rain[rain_days$PRCP >= 360, ]
rain$inches <- rain$PRCP / 25.4
names(rain)[2] <- "mm"

cat("\nRain years used:", min(rain$rain_year), "to", max(rain$rain_year), "\n")
cat("Number of rain years:", nrow(rain), "\n")

# ---- 2. How much and how variable ----

cat("\nAverage rain year total:", round(mean(rain$mm)), "mm (",
    round(mean(rain$inches), 1), "inches )\n")
cat("Median:", round(median(rain$mm)), "mm\n")
cat("Standard deviation:", round(sd(rain$mm)), "mm\n")
cat("Years above 1.5 times the average:",
    sum(rain$mm > 1.5 * mean(rain$mm)), "\n")
cat("Years below half the average:",
    sum(rain$mm < 0.5 * mean(rain$mm)), "\n")

cat("\nFive wettest rain years:\n")
print(head(rain[order(-rain$mm), c("rain_year", "mm", "inches")], 5))
cat("\nFive driest rain years:\n")
print(head(rain[order(rain$mm), c("rain_year", "mm", "inches")], 5))

# ---- 3. Is there a trend? ----

rain$year_c <- rain$rain_year - mean(rain$rain_year)
rain_fit <- lm(mm ~ year_c, data = rain)
print(summary(rain_fit))
cat("\nTrend:", round(coef(rain_fit)["year_c"] * 10, 1), "mm per decade\n")
cat("p-value:", round(summary(rain_fit)$coefficients[2, 4], 3), "\n")

# ---- 4. Plots ----

png("figures/rainfall_by_year.png", width = 900, height = 550, res = 120)
barplot(rain$mm, names.arg = rain$rain_year, col = "steelblue",
        xlab = "Rain year (July to June)", ylab = "Rainfall (mm)",
        main = "San Diego rainfall by rain year")
abline(h = mean(rain$mm), col = "red", lwd = 2)
legend("topright", legend = "Average", col = "red", lwd = 2, bty = "n")
dev.off()

png("figures/rainfall_histogram.png", width = 900, height = 550, res = 120)
hist(rain$mm, breaks = 12, col = "steelblue", border = "white",
     xlab = "Rain year total (mm)", main = "How rain year totals are spread out")
dev.off()

cat("\nSaved plots to the figures folder.\n")
