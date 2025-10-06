#!/usr/bin/env Rscript
# Detailed benchmark comparison with multiple runs

library(DDRTree)

cat("=== DDRTree Detailed Benchmark Comparison ===\n\n")

set.seed(42)

# Generate data
n_genes <- 1000
n_cells <- 4000
n_per_type <- as.integer(n_cells / 3)
X <- matrix(0, nrow = n_genes, ncol = n_cells)
X[, 1:n_per_type] <- matrix(rnorm(n_genes * n_per_type, mean = 5, sd = 2), 
                             nrow = n_genes, ncol = n_per_type)
X[, (n_per_type+1):(2*n_per_type)] <- matrix(rnorm(n_genes * n_per_type, mean = 7, sd = 2), 
                                               nrow = n_genes, ncol = n_per_type)
X[, (2*n_per_type+1):n_cells] <- matrix(rnorm(n_genes * (n_cells - 2*n_per_type), mean = 6, sd = 2), 
                                         nrow = n_genes, ncol = (n_cells - 2*n_per_type))
X <- X + matrix(rnorm(n_genes * n_cells, mean = 0, sd = 0.5), nrow = n_genes)

cat(sprintf("Data: %d genes x %d cells (%.2f MB)\n\n", n_genes, n_cells, object.size(X) / 1024^2))

# Warm-up
cat("Warm-up...\n")
invisible(DDRTree(X[, 1:100], dimensions = 2, maxIter = 2, sigma = 0.001, 
                  lambda = 500, ncenter = 10, param.gamma = 10, 
                  tol = 0.001, verbose = FALSE))

# Multiple runs
n_runs <- 5
times <- numeric(n_runs)

cat(sprintf("\nRunning %d iterations...\n", n_runs))
for (i in 1:n_runs) {
    cat(sprintf("  Run %d/%d... ", i, n_runs))
    gc(reset = TRUE, verbose = FALSE)
    
    start <- Sys.time()
    result <- DDRTree(X, 
                      dimensions = 2, 
                      maxIter = 10, 
                      sigma = 0.001,
                      lambda = NULL,
                      ncenter = 100, 
                      param.gamma = 10, 
                      tol = 0.001, 
                      verbose = FALSE)
    end <- Sys.time()
    
    times[i] <- as.numeric(difftime(end, start, units = "secs"))
    cat(sprintf("%.2f seconds\n", times[i]))
}

cat("\n=== RESULTS ===\n")
cat(sprintf("Mean time:   %.2f seconds\n", mean(times)))
cat(sprintf("Median time: %.2f seconds\n", median(times)))
cat(sprintf("Min time:    %.2f seconds\n", min(times)))
cat(sprintf("Max time:    %.2f seconds\n", max(times)))
cat(sprintf("Std dev:     %.2f seconds\n", sd(times)))
cat(sprintf("\nThroughput:  %.0f cells/second\n", n_cells / mean(times)))
cat(sprintf("Iterations:  %d\n", length(result$objective_vals)))
