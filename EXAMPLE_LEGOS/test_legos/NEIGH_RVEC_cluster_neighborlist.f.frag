!-------------------------------------------------------------------------------
!
! NEIGH_RVEC_cluster_neighborlist
!
!-------------------------------------------------------------------------------
subroutine NEIGH_RVEC_cluster_neighborlist(half, numberOfParticles, coords, &
                                           cutoff, NN, neighborList, RijList)
  use, intrinsic :: iso_c_binding
  use KIM_API_F03
  implicit none

  !-- Transferred variables
  logical,        intent(in)  :: half
  integer(c_int), intent(in)  :: numberOfParticles
  real(c_double), dimension(3,numberOfParticles), &
                  intent(in)  :: coords
  real(c_double), intent(in)  :: cutoff
  integer(c_int), intent(in)  :: NN
  integer(c_int), dimension(NN+1,numberOfParticles), &
                  intent(out) :: neighborList
  real(c_double), dimension(3,NN+1,numberOfParticles), &
                  intent(out) :: RijList

  !-- Local variables
  integer(c_int) i, j, a
  real(c_double) dx(3)
  real(c_double) r2
  real(c_double) cutoff2

  cutoff2 = cutoff**2

  do i=1,numberOfParticles
     a = 1
     do j=1,numberOfParticles
        dx(:) = coords(:, j) - coords(:, i)
        r2 = dot_product(dx, dx)
        if (r2.le.cutoff2) then
           if ((half .and. i.lt.j) .or. (.not.half .and. i.ne.j)) then
              ! atom j is a neighbor of atom i
              a = a+1
              neighborList(a,i) = j
              RijList(:,a-1,i) = dx
           endif
        endif
     enddo
     ! atom i has a-1 neighbors
     neighborList(1,i) = a-1
  enddo

  return

end subroutine NEIGH_RVEC_cluster_neighborlist
