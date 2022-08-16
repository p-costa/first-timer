### Description

Timing module to be used in codes which use MPI and possibly CUDA/OpenACC using NVTX markers.

 * Reports the average time per task for each tagged region by default, but more detailed reporting (minimum/maximum per call and/or per task) is supported too.
 * Times tagged code regions *a la MATLAB* (`timer_tic` and `timer_toc`) using `MPI_WTIME()`.
 * A few different options for tagging the NVTX markers are available: prescribed color, random colored, or round-robin colormap sampling.
 * Supports host-device (a)synchrony for applications accelerated with OpenACC or CUDA (optionally using CUDA streams/OpenACC queues).
 * See the example program `main.f90` illustrating the usage.

### References

The tool took inspiration from [wcdawn/ftime](https://github.com/wcdawn/ftime), and adapted the NVTX bindings in [maxcuda/NVTX_Example](https://github.com/maxcuda/NVTX_example).
