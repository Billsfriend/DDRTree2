# DDRTree News

## Version 0.2.0 (2025-10-03) - Performance-Optimized Fork

### Major Improvements

* **OpenMP Parallelization** - 11x performance improvement
  - Parallelized soft assignment computation (primary bottleneck)
  - Achieved 11x speedup on real-world data (1000 genes × 5536 cells)
  - Execution time reduced from 296.83s to 27.00s
  - Throughput increased from 19 to 205 cells/second
  - No memory overhead or numerical differences

* **Code Optimizations**
  - Efficient matrix broadcasting using Eigen's `replicate()`
  - Pre-allocated matrices to reduce memory allocations
  - Cleaner, more maintainable code structure

* **Build System Improvements**
  - Added `Makevars` for automatic OpenMP compilation
  - Conditional compilation for backward compatibility
  - Thread count detection and reporting

### Documentation

* Added comprehensive performance documentation:
  - `OPENMP_OPTIMIZATION_REPORT.md`: Technical details and analysis
  - `PERFORMANCE_SUMMARY.txt`: Quick reference guide
  - `benchmark_real_data.R`: Reproducible benchmark script

### Notes

* This is a performance-optimized fork of CRAN v0.1.5
* Original algorithm and core functionality unchanged
* Maintains identical numerical results
* Backward compatible - falls back to serial execution if OpenMP unavailable
* Scales linearly with dataset size
* **Maintainer**: Billsfriend <Billsfriend1999@outlook.com>
* **Original Authors**: Xiaojie Qiu, Cole Trapnell, Qi Mao, Li Wang

### Usage

Control thread count for optimal performance:

```r
# Set before loading the package
Sys.setenv(OMP_NUM_THREADS = 8)
library(DDRTree2)
```

Or via shell:
```bash
export OMP_NUM_THREADS=8
Rscript your_script.R
```

---

## Version 0.1.5 (2017-04-14) - Original CRAN Release

### Bug Fixes

* Fixed a problem where DDRTree would return different results on repeated runs 
  given the same inputs. The problem was in two places: kmeans and irlba. We now 
  call irlba with deterministically initialized eigenvectors and kmeans with 
  deterministically selected rows of the input.

---

## Version 0.1.4

### Bug Fixes

* Fixed a build error triggered by recent versions of GCC using the C++14 standard
