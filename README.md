### Description

Simple timing routines to be used in codes which use MPI and possibly CUDA/OpenACC using NVTX markers.

 * A few different options for tagging the NVTX markers are available: prescribed color, random colored, or round-robin colormap sampling.
 * Supports asynchronous host-device (a)synchrony for applications accelerated with OpenACC or CUDA (optionally using CUDA streams/OpenACC queues).
 * Times tagged code regions *a la MATLAB* (`timer_tic` and `timer_toc`) using `MPI_WTIME()`.
 * Reports the average time per task for each tagged region by default, but more detailed reporting (minimum/maximum per call and/or per task) is supported too.
 * See the example program `main.f90` illustrating the usage.

### References

The tool took inspiration from [wcdawn/ftime](https://github.com/wcdawn/ftime), and adapted the NVTX bindings in [maxcuda/NVTX_Example](https://github.com/maxcuda/NVTX_example).
