# DDRTree - Performance-Optimized Fork

[![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)](https://github.com/Billsfriend/DDRTree2)
[![License](https://img.shields.io/badge/license-Artistic--2.0-green.svg)](LICENSE)
[![Performance](https://img.shields.io/badge/speedup-11x-brightgreen.svg)](PERFORMANCE_SUMMARY.txt)

An R implementation of the DDRTree algorithm for learning principal graphs, with **11x performance improvement** through OpenMP parallelization.

## Overview

DDRTree (Discriminative Dimensionality Reduction via Learning a Tree) is a framework for reversed graph embedding (RGE) that projects data into a reduced dimensional space while constructing a principal tree through the middle of the data simultaneously. It excels at inferring ordering and intrinsic structure in single-cell genomics data.

**This fork** adds significant performance optimizations while maintaining identical numerical results and full backward compatibility with the original CRAN package (v0.1.5).

## Performance Improvements

### Benchmark Results (Real Data: 1000 genes × 5536 cells)

**Note**: Speedup scales with available CPU cores. Results below are from a system with ~12-16 cores.

| Metric | Original | Optimized | Improvement |
|--------|----------|-----------|-------------|
| **Execution Time** | 296.83s (4m 57s) | 27.00s | **11.0x faster** ⚡ |
| **Throughput** | 19 cells/s | 205 cells/s | +186 cells/s |
| **Memory Usage** | ~42 MB | ~42 MB | No change |
| **Numerical Results** | Baseline | Identical | ✓ Verified |

**Speedup by CPU Core Count** (estimated):
- 4 cores: ~3-4x speedup
- 8 cores: ~6-7x speedup
- 16 cores: ~11-13x speedup
- 32 cores: ~18-22x speedup
- 80 cores: ~25-30x speedup (near-linear scaling)

### Key Optimizations

1. **OpenMP Parallelization** - Parallelized soft assignment computation (primary bottleneck)
2. **Efficient Matrix Operations** - Using Eigen's optimized broadcasting
3. **Memory Management** - Pre-allocated matrices to reduce allocations

See [PERFORMANCE_SUMMARY.txt](PERFORMANCE_SUMMARY.txt) for detailed metrics and [OPENMP_OPTIMIZATION_REPORT.md](OPENMP_OPTIMIZATION_REPORT.md) for technical details.

## Installation

### From GitHub

```r
# Install devtools if needed
install.packages("devtools")

# Install DDRTree2 (optimized version)
devtools::install_github("Billsfriend/DDRTree2")
```

### System Requirements

- **R** >= 3.0
- **C++11** compiler
- **OpenMP** (optional, for parallel execution - highly recommended)
  - Linux: Usually included with GCC
  - macOS: `brew install libomp`
  - Windows: Included with Rtools

## Usage

### Basic Usage

```r
library(DDRTree2)

# Your data matrix (genes × cells)
data <- your_data_matrix

# Run DDRTree with default parameters
result <- DDRTree(data, 
                  dimensions = 2,
                  maxIter = 20,
                  sigma = 0.001,
                  lambda = NULL,  # Defaults to 5 * ncol(data)
                  ncenter = NULL, # Auto-calculated
                  param.gamma = 10,
                  tol = 0.001,
                  verbose = FALSE)

# Access results
Z <- result$Z        # Reduced dimension space
Y <- result$Y        # Latent centers
W <- result$W        # Projection matrix
stree <- result$stree # Spanning tree
```

### Controlling Thread Count

For optimal performance, set the number of OpenMP threads to match your CPU cores:

```r
# Set before loading the package
# Use all available cores (default)
library(DDRTree2)

# Or explicitly set thread count
Sys.setenv(OMP_NUM_THREADS = 16)  # Adjust based on your CPU
library(DDRTree2)

# Check available cores
parallel::detectCores()
```

Or via shell:
```bash
export OMP_NUM_THREADS=16  # Set to your CPU core count
Rscript your_script.R
```

**Performance Tip**: Speedup scales nearly linearly with CPU cores. On an 80-core machine, expect ~25-30x speedup!

### Recommended ncenter Calculation

For single-cell data, use this formula to calculate optimal `ncenter`:

```r
ddrt_center <- function(ncells, ncells_limit = 100) {
  round(2 * ncells_limit * log(ncells) / (log(ncells) + log(ncells_limit)))
}

ncenter <- ddrt_center(ncol(data))
result <- DDRTree(data, ncenter = ncenter, ...)
```

## Example

```r
library(DDRTree2)

# Load example data
data('iris')
subset_iris_mat <- as.matrix(t(iris[c(1, 2, 52, 103), 1:4]))

# Run DDRTree
result <- DDRTree(subset_iris_mat, 
                  dimensions = 2, 
                  maxIter = 5, 
                  sigma = 1e-2,
                  lambda = 1, 
                  ncenter = 3, 
                  param.gamma = 10, 
                  tol = 1e-2, 
                  verbose = FALSE)

# Visualize reduced dimensions
plot(result$Z[1, ], result$Z[2, ], 
     col = iris[c(1, 2, 52, 103), 'Species'],
     main = "DDRTree Reduced Dimension",
     xlab = "Dimension 1", ylab = "Dimension 2")
```

## Benchmarking

To benchmark on your own data:

```r
source("benchmark_real_data.R")
# Follow the script to load your HDF5 data and run benchmarks
```

## Scalability

Expected performance on different dataset sizes:

| Dataset Size | Original Time | OpenMP Time | Speedup |
|--------------|---------------|-------------|---------|
| 1,000 cells | ~54s | ~5s | ~11x |
| 5,000 cells | ~4.5min | ~25s | ~11x |
| 10,000 cells | ~9min | ~49s | ~11x |
| 20,000 cells | ~18min | ~1.6min | ~11x |
| 50,000 cells | ~45min | ~4min | ~11x |

## Citation

### This Fork (v0.2.0)

If you use this optimized version, please cite:

```
Billsfriend (2025). DDRTree2: Performance-Optimized DDRTree with OpenMP Parallelization.
R package version 0.2.0. https://github.com/Billsfriend/DDRTree2
```

### Original Algorithm

Please also cite the original DDRTree paper:

```
Qi Mao, Li Wang, Steve Goodison, and Yijun Sun (2015).
Dimensionality Reduction via Graph Structure Learning.
The 21st ACM SIGKDD Conference on Knowledge Discovery and Data Mining (KDD'15).
http://dl.acm.org/citation.cfm?id=2783309
```

And the original R package:

```
Xiaojie Qiu, Cole Trapnell, Qi Mao, Li Wang (2017).
DDRTree: Learning Principal Graphs with DDRTree.
R package version 0.1.5. https://CRAN.R-project.org/package=DDRTree
```

## License

This package is licensed under the **Artistic License 2.0**, the same as the original CRAN package.

- **Original Authors**: Xiaojie Qiu, Cole Trapnell, Qi Mao, Li Wang
- **Fork Maintainer**: Billsfriend <Billsfriend1999@outlook.com>
- **Modifications**: OpenMP parallelization and performance optimizations (2025)

See [LICENSE](LICENSE) for full license text.

## Acknowledgments

This is a performance-optimized fork of the original DDRTree package (v0.1.5) from CRAN. The core algorithm and functionality remain unchanged. All optimizations maintain identical numerical results and full backward compatibility.

**Original Package**: https://CRAN.R-project.org/package=DDRTree  
**Original Authors**: Xiaojie Qiu, Cole Trapnell, Qi Mao, Li Wang

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Links

- **GitHub Repository**: https://github.com/Billsfriend/DDRTree2
- **Issue Tracker**: https://github.com/Billsfriend/DDRTree2/issues
- **Performance Report**: [OPENMP_OPTIMIZATION_REPORT.md](OPENMP_OPTIMIZATION_REPORT.md)
- **Original CRAN Package**: https://CRAN.R-project.org/package=DDRTree
