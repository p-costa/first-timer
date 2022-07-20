!
! a simple timer, adapted from https://github.com/wcdawn/ftime (MIT)
!
module mod_timer
  use, intrinsic :: iso_fortran_env, only: dp => real64
  use mpi
#if defined(_USE_NVTX)
  use mod_nvtx
#endif
  implicit none
  private
  public :: timer_start,timer_stop,timer_print,timer_cleanup
  !
  integer, parameter :: max_name_len = 50
  character(max_name_len), allocatable :: timer_names(:)
  integer , allocatable :: timer_counts(:)
  real(dp), allocatable :: timer_tictoc(:),timer_elapsed_acc(:), &
                                           timer_elapsed_min(:), &
                                           timer_elapsed_max(:)
  logical , allocatable :: timer_is_nvtx(:)
  integer :: ntimers = 0
contains
  subroutine timer_print(myid_arg)
    use, intrinsic :: iso_fortran_env, only: stdo => output_unit
    integer , parameter :: MYID_PRINT = 0
    integer , intent(in), optional :: myid_arg
    real(dp), allocatable :: timing_results_acc(:,:), &
                             timing_results_min(:,:), &
                             timing_results_max(:,:)
    integer  :: i,myid,nproc,ierr
    !
    if(present(myid_arg)) then
      myid = myid_arg
    else
      myid = MYID_PRINT
    end if
    allocate(timing_results_acc(ntimers,3), &
             timing_results_min(ntimers,3), &
             timing_results_max(ntimers,3))
    call MPI_COMM_SIZE(MPI_COMM_WORLD,nproc,ierr)
    call MPI_ALLREDUCE(timer_elapsed_acc(:),timing_results_acc(:,1),ntimers,MPI_DOUBLE_PRECISION,MPI_MIN,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(timer_elapsed_acc(:),timing_results_acc(:,2),ntimers,MPI_DOUBLE_PRECISION,MPI_MAX,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(timer_elapsed_acc(:),timing_results_acc(:,3),ntimers,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
    timing_results_acc(:,3) = timing_results_acc(:,3)/nproc
    call MPI_ALLREDUCE(timer_elapsed_min(:),timing_results_min(:,1),ntimers,MPI_DOUBLE_PRECISION,MPI_MIN,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(timer_elapsed_min(:),timing_results_min(:,2),ntimers,MPI_DOUBLE_PRECISION,MPI_MAX,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(timer_elapsed_min(:),timing_results_min(:,3),ntimers,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
    timing_results_min(:,3) = timing_results_min(:,3)/nproc
    call MPI_ALLREDUCE(timer_elapsed_max(:),timing_results_max(:,1),ntimers,MPI_DOUBLE_PRECISION,MPI_MIN,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(timer_elapsed_max(:),timing_results_max(:,2),ntimers,MPI_DOUBLE_PRECISION,MPI_MAX,MPI_COMM_WORLD,ierr)
    call MPI_ALLREDUCE(timer_elapsed_max(:),timing_results_max(:,3),ntimers,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
    timing_results_max(:,3) = timing_results_max(:,3)/nproc
    !
    if(myid == MYID_PRINT) then
      write(stdo,*) ''
      write(stdo,*) '*** timing results [s] ***'
      write(stdo,*) ''
      if(nproc == 1) then
        do i = 1,ntimers
          write(stdo,'(3A)'      ) 'Label: "',trim(timer_names(i)), '"'
          write(stdo,'(A,3E15.7)') 'Elapsed time:', timing_results_acc(i,3:3)
          write(stdo,'(A,I7)'    ) 'Number of calls:', timer_counts(i)
          write(stdo,'(A,3E15.7)') 'Elapsed time (per call average):',timing_results_acc(i,3:3)/timer_counts(i)
          write(stdo,'(A,3E15.7)') 'Elapsed time (per call minimum):',timing_results_min(i,3:3)
          write(stdo,'(A,3E15.7)') 'Elapsed time (per call maximum):',timing_results_max(i,3:3)
          write(stdo,*) ''
        end do
      else
        do i = 1,ntimers
          write(stdo,'(3A)'      ) 'Label: "',trim(timer_names(i)), '"'
          write(stdo,'(A,3E15.7)') 'Maximum, minimum, average elapsed time per task:', timing_results_acc(i,1:3)
          write(stdo,'(A,I7)'    ) 'Number of calls:', timer_counts(i)
          write(stdo,'(A,3E15.7)') 'Maximum, minimum, average elapsed time per task (per call average):', &
                                    timing_results_acc(i,1:3)/timer_counts(i)
          write(stdo,'(A,3E15.7)') 'Maximum, minimum, average elapsed time per task (per call minimum):', &
                                    timing_results_min(i,1:3)
          write(stdo,'(A,3E15.7)') 'Maximum, minimum, average elapsed time per task (per call maximum):', &
                                    timing_results_max(i,1:3)
          write(stdo,*) ''
        end do
      end if
    end if
  end subroutine timer_print
  subroutine timer_start(timer_name,nvtx_id,nvtx_color)
    character(*), intent(in) :: timer_name
    integer         , intent(in), optional :: nvtx_id    ! if <= 0, only label and no color
    character(len=1), intent(in), optional :: nvtx_color ! g/b/y/m/c/r/w following matplotlib's convention
    integer :: idx
    !
    if(.not.allocated(timer_names)) then
      allocate(timer_names(      0), &
               timer_counts(     0), &
               timer_tictoc(     0), &
               timer_elapsed_acc(0), &
               timer_elapsed_min(0), &
               timer_elapsed_max(0), &
               timer_is_nvtx(    0))
    end if
    !
    idx = timer_search(timer_name)
    if (idx <= 0) then
      ntimers = ntimers + 1
      call concatenate_c(timer_names,timer_name)
      timer_counts      = [timer_counts     ,0          ]
      timer_tictoc      = [timer_tictoc     ,0._dp      ]
      timer_elapsed_acc = [timer_elapsed_acc,0._dp      ]
      timer_elapsed_min = [timer_elapsed_min,huge(0._dp)]
      timer_elapsed_max = [timer_elapsed_max,tiny(0._dp)]
      timer_is_nvtx     = [timer_is_nvtx    ,.false.    ]
      idx = ntimers
    end if
    timer_tictoc(idx) = MPI_WTIME()
#if defined(_USE_NVTX)
    if(present(nvtx_id)) then
      if(nvtx_id > 0) then
        if(present(nvtx_color)) then
          call nvtxStartRange(trim(timer_name),nvtx_id,nvtx_color)
        else
          call nvtxStartRange(trim(timer_name),nvtx_id)
        end if
      else
        call nvtxStartRange(trim(timer_name))
      end if
      timer_is_nvtx(idx) = .true.
    end if
#endif
  end subroutine timer_start
  subroutine timer_stop(timer_name)
    character(*), intent(in) :: timer_name
    integer  :: idx
    idx = timer_search(timer_name)
    if (idx > 0) then
      timer_tictoc(idx)      = MPI_WTIME() - timer_tictoc(idx)
      timer_elapsed_acc(idx) =    (timer_elapsed_acc(idx)+timer_tictoc(idx))
      timer_elapsed_min(idx) = min(timer_elapsed_min(idx),timer_tictoc(idx))
      timer_elapsed_max(idx) = max(timer_elapsed_max(idx),timer_tictoc(idx))
      timer_counts(idx)      = timer_counts(idx) + 1
      if(timer_is_nvtx(idx)) then
#if defined(_USE_NVTX)
        call nvtxEndRange 
#endif
      end if
    end if
  end subroutine timer_stop
  subroutine timer_cleanup
    if (.not.allocated(timer_names)) then
      deallocate(timer_names,timer_counts,timer_elapsed_acc,timer_elapsed_min,timer_elapsed_max)
    end if
  end subroutine timer_cleanup
  integer function timer_search(timer_name)
    character(*), intent(in) :: timer_name
    integer :: i
    timer_search = -1
    do i = 1,ntimers
      if (timer_names(i) == timer_name) then
        timer_search = i
      end if
    end do
  end function timer_search
  real(dp) function timer_time(timer_name)
    character(*), intent(in) :: timer_name
    integer :: idx
    timer_time = -1._dp
    idx = timer_search(timer_name)
    if (idx > 0) then
      timer_time = timer_elapsed_acc(idx)
    end if
  end function timer_time
  subroutine concatenate_c(arr,val)
    character(*), intent(inout), allocatable, dimension(:) :: arr
    character(*), intent(in   ) :: val
    character(:), allocatable, dimension(:) :: arr_tmp
    integer :: n
    n = size(arr)
    allocate(arr_tmp,source=arr)
    deallocate(arr); allocate(arr(n+1))
    arr(1:n) = arr_tmp(:); arr(n+1) = val
  end subroutine concatenate_c
end module mod_timer
