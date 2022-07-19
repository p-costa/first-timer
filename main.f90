program main
  use mpi
  use mod_timer
  implicit none
  integer, parameter :: n = 3
  integer :: i,ierr,myid
  
  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD,myid,ierr)
  
  do i = 1,n

    if(myid == 0) print*,'Iteration #',i,'of',n
    if(myid == 0) print*,''

    call timer_start('First Thing',1)
    call sleep(1)
    call timer_stop('First Thing')
    
    call timer_start('Second Instance',2)
    call sleep(1)
    call timer_stop('Second Instance')
    
    call timer_start('Second Instance',2)
    call sleep(1)
    call timer_stop('Second Instance')
    
    call timer_start('First Thing',1)
    call sleep(1)
    call timer_stop('First Thing')

    call timer_start('Third Event',3,'c')
    call sleep(1)
    call timer_stop('Third Event')

    call timer_start('Fourth Event',0)
    call sleep(1)
    call timer_stop('Fourth Event')

  end do
  
  call timer_print(myid)
  call timer_cleanup
  
  call MPI_Finalize(ierr)
end program main
