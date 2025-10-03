#!/usr/bin/env Rscript
# Benchmark DDRTree on real-world data with OpenMP optimizations

library(DDRTree)
library(hdf5r)

cat("=== DDRTree Real Data Benchmark ===\n\n")

# Function to calculate ncenter
ddrt_center <- function(ncells, ncells_limit=100) {
  round(2 * ncells_limit * log(ncells)/(log(ncells) + log(ncells_limit)))
}

# Load real data (sparse matrix in CSC format)
cat("Loading real_matrix.h5 (sparse matrix)...\n")
h5file <- H5File$new("real_matrix.h5", mode = "r")

# Read sparse matrix components
data <- h5file[["unknown/data"]][]
indices <- h5file[["unknown/indices"]][]
indptr <- h5file[["unknown/indptr"]][]
shape <- h5file[["unknown/shape"]][]
genes <- h5file[["unknown/genes"]][]
barcodes <- h5file[["unknown/barcodes"]][]
h5file$close()

cat(sprintf("Sparse matrix shape: %d x %d\n", shape[1], shape[2]))
cat(sprintf("Non-zero elements: %d (%.2f%% sparse)\n", 
            length(data), 100 * (1 - length(data)/(shape[1]*shape[2]))))

# Convert to dense matrix (genes x cells)
# CSC format: data, indices (row indices), indptr (column pointers)
cat("Converting sparse to dense matrix...\n")
X <- matrix(0, nrow = shape[1], ncol = shape[2])
for (j in 1:(length(indptr)-1)) {
    start_idx <- indptr[j] + 1  # R is 1-indexed
    end_idx <- indptr[j+1]
    if (end_idx >= start_idx) {
        rows <- indices[start_idx:end_idx] + 1  # Convert to 1-indexed
        X[rows, j] <- data[start_idx:end_idx]
    }
}

cat(sprintf("Dense matrix dimensions: %d x %d\n", nrow(X), ncol(X)))
cat(sprintf("Memory size: %.2f MB\n", object.size(X) / 1024^2))

n_genes <- nrow(X)
n_cells <- ncol(X)

cat(sprintf("\nFinal dimensions: %d genes x %d cells\n", n_genes, n_cells))
cat(sprintf("Data range: [%.2f, %.2f]\n", min(X, na.rm=TRUE), max(X, na.rm=TRUE)))

# Z-scale on gene rows (standardize each gene)
cat("\nZ-scaling genes (rows)...\n")
X_scaled <- t(scale(t(X)))

# Handle any NaN/Inf from genes with zero variance
if (any(is.na(X_scaled)) || any(is.infinite(X_scaled))) {
    cat("Warning: Found NaN/Inf values after scaling. Replacing with 0...\n")
    X_scaled[is.na(X_scaled)] <- 0
    X_scaled[is.infinite(X_scaled)] <- 0
}

cat(sprintf("Scaled data range: [%.2f, %.2f]\n", min(X_scaled), max(X_scaled)))
cat(sprintf("Scaled data mean: %.2e, sd: %.2f\n", mean(X_scaled), sd(X_scaled)))

# Calculate ncenter
ncenter <- ddrt_center(n_cells)
cat(sprintf("\nCalculated ncenter: %d (for %d cells)\n", ncenter, n_cells))

# DDRTree parameters (using defaults from DDRTree.R)
cat("\nDDRTree parameters:\n")
cat("  dimensions: 2 (default)\n")
cat("  maxIter: 20 (default)\n")
cat("  sigma: 0.001 (default)\n")
cat(sprintf("  lambda: NULL (will default to 5 * %d = %d)\n", n_cells, 5 * n_cells))
cat(sprintf("  ncenter: %d (calculated)\n", ncenter))
cat("  param.gamma: 10 (default)\n")
cat("  tol: 0.001 (default)\n\n")

# Warm-up run
cat("Performing warm-up run with subset...\n")
subset_size <- min(500, n_cells)
invisible(DDRTree(X_scaled[, 1:subset_size], 
                  dimensions = 2, 
                  maxIter = 2, 
                  sigma = 0.001,
                  lambda = NULL, 
                  ncenter = min(50, subset_size/10), 
                  param.gamma = 10, 
                  tol = 0.001, 
                  verbose = FALSE))
cat("Warm-up complete.\n\n")

# Memory before
mem_before <- gc(reset = TRUE)
cat("Memory before run:\n")
print(mem_before)
cat("\n")

# Run benchmark
cat("Starting DDRTree on full dataset...\n")
cat("---------------------------------------------------\n")

start_time <- Sys.time()
result <- DDRTree(X_scaled, 
                  dimensions = 2, 
                  maxIter = 20, 
                  sigma = 0.001,
                  lambda = NULL,  # Will default to 5 * ncol(X)
                  ncenter = ncenter, 
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
cat(sprintf("Dataset: %d genes x %d cells\n", n_genes, n_cells))
cat(sprintf("Total execution time: %.2f seconds (%.2f minutes)\n", 
            elapsed_time, elapsed_time/60))
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
    cat("Objective function convergence:\n")
    n_show <- min(5, length(result$objective_vals))
    for (i in 1:n_show) {
        cat(sprintf("  Iteration %d: %.6e\n", i, result$objective_vals[i]))
    }
    if (length(result$objective_vals) > n_show) {
        cat("  ...\n")
        cat(sprintf("  Iteration %d: %.6e\n", 
                    length(result$objective_vals), 
                    tail(result$objective_vals, 1)))
    }
    
    # Check convergence
    if (length(result$objective_vals) >= 2) {
        final_change <- abs(result$objective_vals[length(result$objective_vals)] - 
                           result$objective_vals[length(result$objective_vals)-1]) / 
                       abs(result$objective_vals[length(result$objective_vals)-1])
        cat(sprintf("\nFinal relative change: %.6e\n", final_change))
        if (final_change < 0.001) {
            cat("✓ Converged (relative change < 0.001)\n")
        } else {
            cat("✗ Did not converge (may need more iterations)\n")
        }
    }
    cat("\n")
}

# Save results
output_file <- "benchmark_real_results.txt"
sink(output_file)
cat("DDRTree Real Data Benchmark Results\n")
cat("====================================\n\n")
cat(sprintf("Date: %s\n", Sys.time()))
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("DDRTree version: %s\n\n", packageVersion("DDRTree")))
cat(sprintf("Dataset: %d genes x %d cells\n", n_genes, n_cells))
cat(sprintf("ncenter: %d\n", ncenter))
cat(sprintf("Execution time: %.2f seconds (%.2f minutes)\n", elapsed_time, elapsed_time/60))
cat(sprintf("Peak memory: %.2f MB\n", mem_used_mb))
cat(sprintf("Throughput: %.0f cells/second\n", n_cells / elapsed_time))
cat(sprintf("Iterations: %d\n", length(result$objective_vals)))
sink()

cat(sprintf("Results saved to: %s\n", output_file))
cat("\nBenchmark complete!\n")
