# 00_load_and_clean.R
# Loads the San Diego daily weather data and gets it ready to use.
# The other scripts call this one with source().
#
# Data: NOAA GHCN-Daily, station USW00023188 (San Diego International
# Airport), 1940 to 2025. Temperatures are in degrees C, rainfall in mm.
# Run all scripts from the project folder so the file path below works.

daily <- read.csv("data/san_diego_daily.csv", stringsAsFactors = FALSE)

# ---- Check the data before using it ----

cat("Station:", unique(daily$NAME), "\n")
cat("Rows:", nrow(daily), "\n")

daily$DATE <- as.Date(daily$DATE)
cat("Date range:", format(min(daily$DATE)), "to", format(max(daily$DATE)), "\n")

# Are any calendar days missing completely?
all_days <- seq(min(daily$DATE), max(daily$DATE), by = "day")
missing_days <- all_days[!(all_days %in% daily$DATE)]
cat("Calendar days with no row:", length(missing_days), "\n")
print(missing_days)

# Rows that have a row but no temperature value
cat("Missing TMAX:", sum(is.na(daily$TMAX)), "\n")
cat("Missing TMIN:", sum(is.na(daily$TMIN)), "\n")
cat("Missing PRCP:", sum(is.na(daily$PRCP)), "\n")

# ---- Add the columns we need ----

daily$year <- as.numeric(format(daily$DATE, "%Y"))
daily$month <- as.numeric(format(daily$DATE, "%m"))

# The data has daily high (TMAX) and low (TMIN) but no daily average,
# so use the midpoint. This is a simple estimate of the daily mean.
daily$TAVG <- (daily$TMAX + daily$TMIN) / 2
