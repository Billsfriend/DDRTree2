#include <R.h>
#include <Rinternals.h>
#include <stdlib.h> // for NULL
#include <R_ext/Rdynload.h>

/* FIXME:
Check these declarations against the C/Fortran source code.
*/

/* .Call calls */
extern SEXP DDRTree2_DDRTree_reduce_dim(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP DDRTree2_pca_projection(SEXP, SEXP);
extern SEXP DDRTree2_sqdist(SEXP, SEXP);

static const R_CallMethodDef CallEntries[] = {
    {"DDRTree2_DDRTree_reduce_dim", (DL_FUNC) &DDRTree2_DDRTree_reduce_dim, 12},
    {"DDRTree2_pca_projection",     (DL_FUNC) &DDRTree2_pca_projection,      2},
    {"DDRTree2_sqdist",             (DL_FUNC) &DDRTree2_sqdist,              2},
    {NULL, NULL, 0}
};

void R_init_DDRTree2(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
