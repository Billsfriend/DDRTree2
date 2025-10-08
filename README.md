# DDRTree - Performance-Optimized Fork

[![r-universe version](https://billsfriend.r-universe.dev/DDRTree2/badges/version)](https://billsfriend.r-universe.dev/DDRTree2)
[![r-universe status](https://billsfriend.r-universe.dev/DDRTree2/badges/checks)](https://billsfriend.r-universe.dev/DDRTree2)
[![License](https://img.shields.io/badge/license-Artistic--2.0-green.svg)](LICENSE)

An R implementation of the DDRTree algorithm for learning principal graphs, with **10-20x performance improvement** through OpenMP parallelization.

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

### From R-Universe

```r
# Enable this universe
options(repos = c(
    billsfriend = 'https://billsfriend.r-universe.dev',
    CRAN = 'https://cloud.r-project.org'))

# Install package
install.packages('DDRTree2')
```

#### Linux binary from R-universe

If you are using Ubuntu 24.04 (noble), binary build from R-Universe may save your time from compiling source in `install.packages()`:

```r
linux_binary_repo <- function(universe){
  sprintf('https://%s.r-universe.dev/bin/linux/noble-%s/%s/', 
    universe,
    R.version$arch, 
    substr(getRversion(), 1, 3))
}

options(repos = linux_binary_repo(c('billsfriend', 'cran')))
install.packages('DDRTree2')
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

For single-cell data, use this formula from `monocle` package to calculate optimal `ncenter`:

```r
ddrt_center <- function(ncells, ncells_limit = 100) {
  round(2 * ncells_limit * log(ncells) / (log(ncells) + log(ncells_limit)))
}

ncenter <- ddrt_center(ncol(data))
result <- DDRTree(data, ncenter = ncenter, ...)
```

## Benchmarking

To benchmark on your own data:

```r
source("benchmark_real_data.R")
# Follow the script to load your HDF5 data and run benchmarks
```

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
