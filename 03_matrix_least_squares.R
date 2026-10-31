# 03_matrix_least_squares.R
# Redo the temperature trend using matrices instead of lm(), then check
# that the answers match. Also shows why centering the year matters.
#
# For a model y = X * beta, the best fit satisfies the normal equations:
#     (X^T X) beta = X^T y

source("00_load_and_clean.R")

annual <- aggregate(TAVG ~ year, data = daily, FUN = mean)
y <- annual$TAVG
year <- annual$year

# ---- 1. Straight line fit with matrices ----
# Design matrix: a column of 1s for the intercept, a column of years.

X <- cbind(1, year)
cat("\nDesign matrix:", nrow(X), "rows by", ncol(X), "columns\n")

XtX <- t(X) %*% X
Xty <- t(X) %*% y
beta_by_hand <- solve(XtX, Xty)

cat("\nCoefficients from the normal equations:\n")
print(beta_by_hand)

# ---- 2. Compare with lm() ----

lm_fit <- lm(y ~ year)
cat("\nCoefficients from lm():\n")
print(coef(lm_fit))
cat("\nLargest difference:", max(abs(beta_by_hand - coef(lm_fit))), "\n")

# ---- 3. Same problem with QR decomposition ----
# This is what lm() uses inside. It never forms X^T X.

beta_qr <- qr.solve(X, y)
cat("\nCoefficients from QR:\n")
print(beta_qr)

# ---- 4. Why centering the year helps ----
# The condition number measures how much rounding errors can get
# magnified. A large number means a less stable calculation.

year_c <- year - mean(year)
X_c <- cbind(1, year_c)

cat("\nCondition number of X^T X, raw year:     ",
    format(kappa(XtX, exact = TRUE), scientific = TRUE, digits = 3), "\n")
cat("Condition number of X^T X, centered year:",
    format(kappa(t(X_c) %*% X_c, exact = TRUE), scientific = TRUE, digits = 3), "\n")

# ---- 5. Adding a year squared term ----
# With raw years the columns are nearly copies of each other, and the
# normal equations can fail. tryCatch lets the script keep going.

X_quad_raw <- cbind(1, year, year^2)
result <- tryCatch(
  solve(t(X_quad_raw) %*% X_quad_raw, t(X_quad_raw) %*% y),
  error = function(e) {
    cat("\nNormal equations failed with raw years:\n  ",
        conditionMessage(e), "\n")
    NULL
  }
)

X_quad_c <- cbind(1, year_c, year_c^2)
beta_quad_c <- solve(t(X_quad_c) %*% X_quad_c, t(X_quad_c) %*% y)
cat("\nQuadratic fit with centered years (normal equations):\n")
print(beta_quad_c)
cat("\nQuadratic fit from lm():\n")
print(coef(lm(y ~ year_c + I(year_c^2))))
