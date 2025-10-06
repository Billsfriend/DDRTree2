#!/usr/bin/env Rscript
# Micro-benchmark for sq_dist function specifically

library(DDRTree)
library(microbenchmark)

cat("=== Micro-benchmark: sqdist function ===\n\n")

set.seed(42)

# Test different matrix sizes
test_sizes <- list(
    list(name = "Small (100x100)", rows = 100, cols = 100),
    list(name = "Medium (1000x1000)", rows = 1000, cols = 1000),
    list(name = "Large (1000x4000)", rows = 1000, cols = 4000)
)

for (test in test_sizes) {
    cat(sprintf("\n%s:\n", test$name))
    cat(sprintf("  Matrix dimensions: %d x %d\n", test$rows, test$cols))
    
    a <- matrix(rnorm(test$rows * test$cols), nrow = test$rows)
    b <- matrix(rnorm(test$rows * test$cols), nrow = test$rows)
    
    # Run benchmark
    result <- microbenchmark(
        sqdist(a, b),
        times = 20,
        unit = "ms"
    )
    
    cat(sprintf("  Mean time: %.2f ms\n", mean(result$time) / 1e6))
    cat(sprintf("  Median time: %.2f ms\n", median(result$time) / 1e6))
}

cat("\n=== Testing full DDRTree on smaller dataset ===\n")
# Smaller dataset to see if optimizations show up
n_genes <- 500
n_cells <- 1000
X <- matrix(rnorm(n_genes * n_cells, mean = 5, sd = 2), nrow = n_genes)

result <- microbenchmark(
    DDRTree(X, dimensions = 2, maxIter = 5, sigma = 0.001,
            lambda = NULL, ncenter = 50, param.gamma = 10, 
            tol = 0.001, verbose = FALSE),
    times = 3,
    unit = "s"
)

cat(sprintf("Mean time: %.2f seconds\n", mean(result$time) / 1e9))
cat(sprintf("Median time: %.2f seconds\n", median(result$time) / 1e9))
