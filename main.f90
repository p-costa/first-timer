program main
  use mpi
  use mod_timer
  implicit none
  interface sleep
    procedure sleep_r
  end interface
  integer, parameter :: n = 3
  integer :: i,ierr,myid

  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD,myid,ierr)

  do i = 1,n

    if(myid == 0) print*,'Iteration #',i,'of',n
    if(myid == 0) print*,''

    call timer_tic('First Thing',1)
    call sleep(0.10)
    call timer_tic('Sub-First Thing',0)
    call sleep(0.05)
    call timer_toc('Sub-First Thing')
    call timer_toc('First Thing')

    call timer_tic('Second Instance',2)
    call sleep(0.15)
    call timer_toc('Second Instance')

    call timer_tic('Second Instance',2)
    call sleep(0.15)
    call timer_toc('Second Instance')

    call timer_tic('First Thing',1)
    call sleep(0.15)
    call timer_toc('First Thing')

    call timer_tic('Third Event',3,'c')
    call sleep(0.25)
    call timer_toc('Third Event')

    call timer_tic('Fourth Event',0)
    call sleep(0.35)
    call timer_toc('Fourth Event')

  end do

  call timer_print(myid)
  call timer_cleanup

  call MPI_Finalize(ierr)
contains
  subroutine sleep_r(s)
    implicit none
    interface
      subroutine usleep(us) bind(C)
        use, intrinsic ::  iso_c_binding, only:c_int
        integer(c_int), value :: us
      end subroutine usleep
    end interface
    real, intent(in) :: s
    call usleep(int(s*10**6))
  end subroutine sleep_r
end program main
