// Code must be built with appropriate paths for VTune include file (ittnotify.h) and library (-littnotify)
#include <ittnotify.h>

__SSC_MARK(0x111); // start SDE tracing, note it uses 2 underscores
__itt_resume(); // start VTune, again use 2 underscores

for (k=0; k<NTIMES; k++) {
 #pragma omp parallel for
 for (j=0; j<STREAM_ARRAY_SIZE; j++)
 a[j] = b[j]+scalar*c[j];
}

__itt_pause(); // stop VTune
__SSC_MARK(0x222); // stop SDE tracing
