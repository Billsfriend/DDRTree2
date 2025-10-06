#!/usr/bin/env Rscript
# Benchmark script for DDRTree optimization
# Tests performance on 4000 cells x 1000 genes matrix

library(DDRTree)

cat("=== DDRTree Performance Benchmark ===\n\n")

# Set seed for reproducibility
set.seed(42)

# Generate synthetic data: 1000 genes x 4000 cells
n_genes <- 1000
n_cells <- 4000
cat(sprintf("Generating synthetic data: %d genes x %d cells\n", n_genes, n_cells))

# Create realistic single-cell-like data with some structure
# Simulate 3 cell types with different expression patterns
n_per_type <- as.integer(n_cells / 3)
X <- matrix(0, nrow = n_genes, ncol = n_cells)

# Cell type 1
X[, 1:n_per_type] <- matrix(rnorm(n_genes * n_per_type, mean = 5, sd = 2), 
                             nrow = n_genes, ncol = n_per_type)
# Cell type 2
X[, (n_per_type+1):(2*n_per_type)] <- matrix(rnorm(n_genes * n_per_type, mean = 7, sd = 2), 
                                               nrow = n_genes, ncol = n_per_type)
# Cell type 3
X[, (2*n_per_type+1):n_cells] <- matrix(rnorm(n_genes * (n_cells - 2*n_per_type), mean = 6, sd = 2), 
                                         nrow = n_genes, ncol = (n_cells - 2*n_per_type))

# Add some noise
X <- X + matrix(rnorm(n_genes * n_cells, mean = 0, sd = 0.5), nrow = n_genes)

cat(sprintf("Data dimensions: %d x %d\n", nrow(X), ncol(X)))
cat(sprintf("Data range: [%.2f, %.2f]\n", min(X), max(X)))
cat(sprintf("Memory size: %.2f MB\n\n", object.size(X) / 1024^2))

# Benchmark parameters
cat("DDRTree parameters:\n")
cat("  dimensions: 2\n")
cat("  maxIter: 10\n")
cat("  sigma: 0.001\n")
cat("  lambda: 5 * ncol(X) = ", 5 * ncol(X), "\n")
cat("  ncenter: 100\n")
cat("  param.gamma: 10\n")
cat("  tol: 0.001\n\n")

# Warm-up run (small subset to load libraries)
cat("Performing warm-up run...\n")
invisible(DDRTree(X[, 1:100], dimensions = 2, maxIter = 2, sigma = 0.001, 
                  lambda = 500, ncenter = 10, param.gamma = 10, 
                  tol = 0.001, verbose = FALSE))
cat("Warm-up complete.\n\n")

# Memory before
mem_before <- gc(reset = TRUE)
cat("Memory before run:\n")
print(mem_before)
cat("\n")

# Run benchmark
cat("Starting benchmark...\n")
cat("---------------------------------------------------\n")

start_time <- Sys.time()
result <- DDRTree(X, 
                  dimensions = 2, 
                  maxIter = 10, 
                  sigma = 0.001,
                  lambda = NULL,  # Will default to 5 * ncol(X)
                  ncenter = 100, 
                  param.gamma = 10, 
                  tol = 0.001, 
                  verbose = FALSE)
end_time <- Sys.time()

elapsed_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

cat("---------------------------------------------------\n")
cat("Benchmark complete!\n\n")

# Memory after
mem_after <- gc()
cat("Memory after run:\n")
print(mem_after)
cat("\n")

# Calculate memory usage
mem_used_mb <- (mem_after[2, 2] - mem_before[2, 2])

# Results
cat("=== BENCHMARK RESULTS ===\n")
cat(sprintf("Total execution time: %.2f seconds\n", elapsed_time))
cat(sprintf("Peak memory usage: %.2f MB\n", mem_used_mb))
cat(sprintf("Throughput: %.0f cells/second\n", n_cells / elapsed_time))
cat(sprintf("Iterations completed: %d\n", length(result$objective_vals)))
cat("\n")

# Output dimensions
cat("Output dimensions:\n")
cat(sprintf("  Z (reduced space): %d x %d\n", nrow(result$Z), ncol(result$Z)))
cat(sprintf("  Y (latent centers): %d x %d\n", nrow(result$Y), ncol(result$Y)))
cat(sprintf("  W (projection): %d x %d\n", nrow(result$W), ncol(result$W)))
cat("\n")

# Convergence info
if (length(result$objective_vals) > 1) {
    cat("Objective function values:\n")
    for (i in 1:min(5, length(result$objective_vals))) {
        cat(sprintf("  Iteration %d: %.6e\n", i, result$objective_vals[i]))
    }
    if (length(result$objective_vals) > 5) {
        cat("  ...\n")
        cat(sprintf("  Iteration %d: %.6e\n", 
                    length(result$objective_vals), 
                    tail(result$objective_vals, 1)))
    }
    cat("\n")
}

# Save results to file
output_file <- "benchmark_results.txt"
sink(output_file)
cat("DDRTree Benchmark Results\n")
cat("=========================\n\n")
cat(sprintf("Date: %s\n", Sys.time()))
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("DDRTree version: %s\n\n", packageVersion("DDRTree")))
cat(sprintf("Data size: %d genes x %d cells\n", n_genes, n_cells))
cat(sprintf("Execution time: %.2f seconds\n", elapsed_time))
cat(sprintf("Peak memory: %.2f MB\n", mem_used_mb))
cat(sprintf("Throughput: %.0f cells/second\n", n_cells / elapsed_time))
cat(sprintf("Iterations: %d\n", length(result$objective_vals)))
sink()

cat(sprintf("Results saved to: %s\n", output_file))
cat("\nBenchmark complete!\n")
