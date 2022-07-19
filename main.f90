program main
  use mpi
  use mod_timer
  implicit none
  integer :: ierr,myid
  
  call MPI_Init(ierr)
  call MPI_Comm_rank(MPI_COMM_WORLD,myid,ierr)
  
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
  
  call timer_print(myid)
  call timer_cleanup
  
  call MPI_Finalize(ierr)
end program main
