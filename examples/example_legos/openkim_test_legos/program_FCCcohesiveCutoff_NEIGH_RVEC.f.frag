!*******************************************************************************
!**
!**  PROGRAM TEST_NAME_STR
!**
!**  KIM compliant program to find (using the Golden section search algorithm)
!**  the minimum energy of one particle in a periodic FCC crystal (spec="SPECIES_NAME_STR") as a
!**  function of lattice spacing.
!**
!**  Works with the following NBC methods:
!**        NEIGH_RVEC_H
!**        NEIGH_RVEC_F
!**
!*******************************************************************************

!-------------------------------------------------------------------------------
!
! Main program
!
!-------------------------------------------------------------------------------
program TEST_NAME_STR
  use, intrinsic :: iso_c_binding
  use KIM_API_F03
  use mod_neighborlist
  implicit none
  integer(c_int), parameter :: cd = c_double ! used for literal constants

!============================== VARIABLE DEFINITIONS ==========================

  ! parameters controlling behavior of test
  !
  character(len=KIM_KEY_STRING_LENGTH), parameter :: testname = "TEST_NAME_STR"
  character(len=KIM_KEY_STRING_LENGTH), parameter :: testkimfile = "descriptor.kim"
  character(len=2), parameter :: specname    = 'SPECIES_NAME_STR'
  real(c_double),   parameter :: TOL         = 1.0e-8_cd
  real(c_double),   parameter :: FCCspacing  = FCC_SPACING_STR
  real(c_double),   parameter :: MinSpacing  = 0.800_cd*FCCspacing
  real(c_double),   parameter :: MaxSpacing  = 1.200_cd*FCCspacing
  integer(c_int),   parameter :: DIM         = 3
  integer(c_int),   parameter :: SupportHalf = 1            ! True

  ! significant local variables
  !
  real(c_double) :: FinalSpacing       ! crystal lattice parameter
  real(c_double) :: FinalEnergy        ! energy per particle of crystal
                                       ! at current spacing
  integer(c_int) :: CellsPerCutoff     ! number of unit cells along
                                       ! box (of size cutoff) side
  real(c_double) :: MaxCutoff          ! maximum value for cutoff radius
  integer(c_int) :: N                          ! number of particles

  ! neighbor list
  !
  type(neighObject_type), target :: neighObject
  integer(c_int)  :: NNeighbors  ! maximum number of neighbors for a particle

  ! KIM variables
  !
  character(len=KIM_KEY_STRING_LENGTH) :: modelname  ! KIM-compliant model name
  type(c_ptr)    :: pkim          ! pointer to KIM API object
  integer(c_int) :: ier           ! error flag

  real(c_double), pointer :: param_cutoff;  type(c_ptr) :: pparam_cutoff

  ! other variables
  !
  real(c_double), external  ::  get_model_cutoff_firsttime
  integer(c_int), external  ::  check_model_parameters
  integer(c_int)            ::  idum

!========================= END VARIABLE DEFINITIONS ==========================


  ! Read in KIM Model name to use
  !
  print '("Please enter a valid KIM model name: ")'
  read(*,*) modelname


  ! We'll use just one particle for this calculation!
  !
  N = 1


  ! Setup the KIM API object
  !
  call setup_KIM_API_object(pkim, testkimfile, modelname, N, specname, SupportHalf)


  ! check for PARAM_FREE_cutoff
  ier = check_model_parameters(pkim)
  if (ier.ne.KIM_STATUS_OK) then
     ! PARAM_FREE_cutoff is not provided by the Model
     idum = kim_api_report_error(__LINE__, THIS_FILE_NAME, &
                                   "exiting...", ier);
     stop
  endif
  !
  ! access the PARAM_FREE_cutoff parameter
  !
  pparam_cutoff = kim_api_get_data(pkim, "PARAM_FREE_cutoff", ier)
  if (ier.lt.KIM_STATUS_OK) then
     idum = kim_api_report_error(__LINE__, THIS_FILE_NAME, &
                                 "kim_api_get_data", ier)
     stop
  endif
  call c_f_pointer(pparam_cutoff, param_cutoff)

  ! Set MaxCutoff to be 2.0 more than the Model's normal cutoff
  !
  MaxCutoff = param_cutoff + 2.0_cd


  ! Set up for first iteration of the loop over the cutoff radius
  param_cutoff = param_cutoff - 2.0_cd
  ier = kim_api_model_reinit(pkim)
  if (ier.lt.KIM_STATUS_OK) then
     idum = kim_api_report_error(__LINE__, THIS_FILE_NAME, &
                                 "kim_api_model_reinit", ier)
     stop
  endif

  ! allocate storage for neighbor lists
  ! and store necessary pointers in KIM API object
  !

  ! determine maximum number of neighbors we will need
  !
  ! use 0.05_cd as a saftey factor
  CellsPerCutoff = ceiling(param_cutoff/MinSpacing+ 0.05_cd)
  NNeighbors = 4*((2*CellsPerCutoff + 1)**3)
  !
  ! allocate memory for the neighbor list and Rij vectors
  !
  allocate(neighObject%neighborList(NNeighbors+1,N))
  allocate(neighObject%RijList(3,NNeighbors+1,N))
  call setup_neighborlist_KIM_access(pkim, neighObject)
  !

  ! loop over an increasing cutoff radius
  do while (param_cutoff .le. MaxCutoff)
     !
     ! find equilibrium spacing by minimizing coheseive energy with respect
     ! to the periodic box size for the current cutoff value
     !
     call NEIGH_RVEC_compute_equilibrium_spacing(pkim, &
          DIM,CellsPerCutoff,MinSpacing,MaxSpacing,    &
          TOL,N,neighObject,.false.,FinalSpacing,FinalEnergy)

     ! print results to screen
     !
     print '(80(''-''))'
     print '("This is Test          : ",A)', trim(testname)
     print '("Results for KIM Model : ",A)', trim(modelname)
     print *
     print '("Found minimum energy configuration to within",ES25.15)', TOL
     print *
     print '("cutoff = ",ES25.15)', param_cutoff
     print *
     print '("Energy/part = ",ES25.15,"; Spacing = ",ES25.15)', FinalEnergy, &
           FinalSpacing
     print '(80(''-''))'

     !
     ! increment cutoff
     !
     param_cutoff = param_cutoff + 1.0
     ier = kim_api_model_reinit(pkim)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error(__LINE__, THIS_FILE_NAME, &
                                    "kim_api_model_reinit", ier)
        stop
     endif

  enddo

  ! Don't forget to free and/or deallocate
  !
  deallocate(neighObject%neighborList)
  deallocate(neighObject%RijList)
  call free_KIM_API_object(pkim)

  stop

end program TEST_NAME_STR

!-------------------------------------------------------------------------------
!
! check_model_parameters :
!
!    Scan the Model's parameters and return 1 in PARAM_FREE_cutoff is in the
!    list and 0 if it is not in the list
!
!-------------------------------------------------------------------------------
integer(c_int) function check_model_parameters(pkim)
  use, intrinsic :: iso_c_binding
  use KIM_API_F03
  implicit none

  !-- Transferred variables
  type(c_ptr), intent(in) :: pkim

  !-- Local variables
  character(len=KIM_KEY_STRING_LENGTH) :: parameter
  integer(c_int) :: nParams
  integer(c_int) :: maxStringLength
  integer(c_int) :: paramIndex
  integer(c_int) :: i
  integer(c_int) :: ier

  ier = kim_api_get_num_params(pkim, nParams, maxStringLength)

  print '("The model has defined the following parameters:")'

  do i=1,nParams
     ier = kim_api_get_parameter(pkim, i, parameter)
     print *, i, trim(parameter)
     if (index(parameter,"PARAM_FREE_cutoff").eq.1) then
        paramIndex = i
     endif
  enddo

  if (paramIndex .gt. 0) then
     print '("PARAM_FREE_cutoff IS in the list, at index ",I2)', paramIndex
     check_model_parameters = 1
  else
     print '("PARAM_FREE_cutoff is NOT in the parameter list.")'
     check_model_parameters = 0
  endif

  return

end function check_model_parameters
