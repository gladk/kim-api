!
! CDDL HEADER START
!
! The contents of this file are subject to the terms of the Common Development
! and Distribution License Version 1.0 (the "License").
!
! You can obtain a copy of the license at
! http://www.opensource.org/licenses/CDDL-1.0.  See the License for the
! specific language governing permissions and limitations under the License.
!
! When distributing Covered Code, include this CDDL HEADER in each file and
! include the License file in a prominent location with the name LICENSE.CDDL.
! If applicable, add the following below this CDDL HEADER, with the fields
! enclosed by brackets "[]" replaced with your own identifying information:
!
! Portions Copyright (c) [yyyy] [name of copyright owner]. All rights reserved.
!
! CDDL HEADER END
!

!
! Copyright (c) 2012, Regents of the University of Minnesota.  All rights reserved.
!
! Contributors:
!    Ellad B. Tadmor
!


!*******************************************************************************
!**
!**  PROGRAM TEST_NAME_STR
!**
!**  KIM compliant program to perform numerical derivative check on a model
!**
!**  Works with the following NBC methods:
!**        CLUSTER
!**        MI_OPBC_H
!**        MI_OPBC_F
!**        NEIGH_PURE_H
!**        NEIGH_PURE_F
!**        NEIGH_RVEC_F
!**
!**  Release: This file is part of the openkim-api.git repository.
!**
!*******************************************************************************

#include "KIM_API_status.h"
#define TRUEFALSE(TRUTH) merge(1,0,(TRUTH))

!-------------------------------------------------------------------------------
!
! Main program
!
!-------------------------------------------------------------------------------
program TEST_NAME_STR
  use KIM_API
  implicit none

  integer, external  :: get_neigh_no_Rij
  integer, external  :: get_neigh_Rij
  real*8,  parameter :: FCCspacing     = FCC_SPACING_STR
  integer, parameter :: nCellsPerSide  = 2
  integer, parameter :: DIM            = 3
  real*8,  parameter :: cutpad         = 0.75d0
  integer, parameter :: max_types      = 20     ! most species a Model can support
  integer, parameter :: max_NBCs       = 20     ! maximum number of NBC methods
  real*8,  parameter :: eps_prec       = epsilon(1.d0)

  integer, parameter :: &
       N = 4*(nCellsPerSide)**3 + 6*(nCellsPerSide)**2 + 3*(nCellsPerSide) + 1
  integer(kind=kim_intptr), parameter  :: SizeOne = 1
  real*8, allocatable                  :: forces_num(:,:)
  real*8, allocatable                  :: forces_num_err(:,:)
  character(len=3)                     :: model_types(max_types)
  character(len=KIM_KEY_STRING_LENGTH) :: model_NBCs(max_NBCs)
  integer                              :: num_types
  integer                              :: num_NBCs
  character(len=4)                     :: passfail
  real*8                               :: forcediff
  real*8                               :: forcediff_sumsq
  real*8                               :: weight
  real*8                               :: weight_sum
  real*8                               :: alpha
  real*8                               :: term
  real*8                               :: term_max
  double precision,        allocatable :: cluster_coords(:,:)
  character(len=3),        allocatable :: cluster_types(:)
  integer I,J,Imax,Jmax,type

  ! neighbor list
  integer,                  allocatable :: neighborList(:,:)
  integer(kind=kim_intptr), allocatable :: NLRvecLocs(:)
  double precision,         allocatable :: RijList(:,:,:)
  double precision,         allocatable :: coordsave(:,:)
  logical do_update_list

  !
  ! KIM variables
  !
  character*80              :: testname     = "TEST_NAME_STR"
  character*80              :: modelname
  character(len=KIM_KEY_STRING_LENGTH) :: NBC_Method; pointer(pNBC_Method,NBC_Method)
  integer nbc  ! 0- MI_OPBC_H, 1- MI_OPBC_F, 2- NEIGH_PURE_H, 3- NEIGH_PURE_F, 4- NEIGH-RVCE-F, 5- CLUSTER
  integer(kind=kim_intptr)  :: pkim
  integer                   :: ier, idum, inbc
  integer numberOfParticles;   pointer(pnAtoms,numberOfParticles)
  integer numContrib;          pointer(pnumContrib,numContrib)
  integer numberParticleTypes; pointer(pnparticleTypes,numberParticleTypes)
  integer particleTypesdum(1); pointer(pparticleTypesdum,particleTypesdum)

  real*8 cutoff;               pointer(pcutoff,cutoff)
  real*8 energy;               pointer(penergy,energy)
  real*8 coordum(DIM,1);       pointer(pcoor,coordum)
  real*8 forcesdum(DIM,1);     pointer(pforces,forcesdum)
  real*8 boxSideLengths(DIM);  pointer(pboxSideLengths,boxSideLengths)
  real*8, pointer  :: coords(:,:), forces(:,:)
  integer, pointer :: particleTypes(:)
  integer middleDum
  character(len=10000) :: test_descriptor_string
  real*8 rnd, deriv, deriv_err

  ! Initialize error flag
  ier = KIM_STATUS_OK

  ! Get KIM Model name to use
  print '("Please enter a valid KIM model name: ")'
  read(*,*) modelname

  ! Get list of particle types supported by the model
  !
  call Get_Model_Supported_Types(modelname, max_types, model_types, num_types, ier)

  ! Get list of NBCs supported by the model
  !
  call Get_Model_NBC_methods(modelname, max_NBCs, model_NBCs, num_NBCs, ier)
  if (ier.lt.KIM_STATUS_OK) then
     idum = kim_api_report_error_f(__LINE__, __FILE__, "Get_Model_NBC_methods", ier)
     stop
  endif

  ! Setup random cluster
  !
  allocate(cluster_coords(3,N),cluster_types(N))
  do i=1,N
     call random_number(rnd)  ! return random number between 0 and 1
     type = 1 + int(rnd*num_types)
     cluster_types(i) = model_types(type)
  enddo
  call create_FCC_configuration(FCCspacing, nCellsPerSide, .false., &
                                cluster_coords, middleDum)
  ! Randomly perturb all atoms
  !
  do I=1,N
     do J=1,DIM
        call random_number(rnd)  ! return random number between 0 and 1
        cluster_coords(J,I) = cluster_coords(J,I) + 0.1d0*(rnd-0.5d0)
     enddo
  enddo

  ! Print output header
  !
  print *
  print *,'VERIFICATION CHECK: NUMERICAL DERIVATIVE VERIFICATION OF FORCES'
  print *
  print '(120(''-''))'
  print '("This is Test          : ",A)', testname
  print '("Results for KIM Model : ",A)', modelname
  print *

  ! Loop over all NBCs and perform numerical derivative check for each one
  !
  do inbc = 1, num_NBCs

     ! Write out KIM descriptor string for Test for current NBC
     !
     call Write_KIM_descriptor(model_NBCs(inbc), max_types, model_types, num_types, &
                               test_descriptor_string, ier)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "Write_KIM_descriptor", ier)
        stop
     endif

     ! Create empty KIM object conforming to fields in the KIM descriptor files
     ! of the Test and Model
     !
     ier = kim_api_string_init_f(pkim,trim(test_descriptor_string)//char(0),modelname)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_string_init_f", ier)
        stop
     endif

     ! Double check that the NBC method being used is what we think it is
     !
     pNBC_Method = kim_api_get_nbc_method_f(pkim, ier) ! don't forget to free
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_get_nbc_method", ier)
        stop
     endif
     if (index(NBC_Method,trim(model_NBCs(inbc))).ne.1) then
        ier = KIM_STATUS_FAIL
        idum = kim_api_report_error_f(__LINE__, __FILE__, &
              "Internal Error: Selected NBC method different from requested value", ier)
        stop
     endif

     ! Set NBC code based on selected NBC method
     !
     if (index(NBC_Method,"MI_OPBC_H").eq.1) then
        nbc = 0
     elseif (index(NBC_Method,"MI_OPBC_F").eq.1) then
        nbc = 1
     elseif (index(NBC_Method,"NEIGH_PURE_H").eq.1) then
        nbc = 2
     elseif (index(NBC_Method,"NEIGH_PURE_F").eq.1) then
        nbc = 3
     elseif (index(NBC_Method,"NEIGH_RVEC_F").eq.1) then
        nbc = 4
     elseif (index(NBC_Method,"CLUSTER").eq.1) then
        nbc = 5
     else
        ier = KIM_STATUS_FAIL
        idum = kim_api_report_error_f(__LINE__, __FILE__, "Unknown NBC method", ier)
        stop
     endif

     ! Allocate memory via the KIM system
     !
     call kim_api_allocate_f(pkim, N, num_types, ier)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_allocate_f", ier)
        stop
     endif

     ! Allocate storage for neighbor lists and
     ! store pointers to neighbor list object and access function
     !
     if (nbc.le.4) then
        allocate(neighborList(N+1,N))
        if (nbc.le.3) then
           ier = kim_api_set_data_f(pkim, "neighObject", SizeOne, loc(neighborList))
           if (ier.lt.KIM_STATUS_OK) then
              idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_set_data_f", ier)
              stop
           endif
        else
           allocate(RijList(DIM,N+1,N), NLRvecLocs(3))
           NLRvecLocs(1) = loc(neighborList)
           NLRvecLocs(2) = loc(RijList)
           NLRvecLocs(3) = N
           ier = kim_api_set_data_f(pkim, "neighObject", SizeOne, loc(NLRvecLocs))
           if (ier.lt.KIM_STATUS_OK) then
              idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_set_data_f", ier)
              stop
           endif
        endif
     endif
   
     ! Set pointer in KIM object to neighbor list routine
     !
     if (nbc.eq.0) then
        ier = kim_api_set_data_f(pkim, "get_neigh", SizeOne, loc(get_neigh_no_Rij))
        if (ier.lt.KIM_STATUS_OK) then
           idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_set_data_f", ier)
           stop
        endif
        elseif (nbc.eq.1) then
        ier = kim_api_set_data_f(pkim, "get_neigh", SizeOne, loc(get_neigh_no_Rij))
        if (ier.lt.KIM_STATUS_OK) then
           idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_set_data_f", ier)
           stop
        endif
     elseif (nbc.eq.2) then
        ier = kim_api_set_data_f(pkim, "get_neigh", SizeOne, loc(get_neigh_no_Rij))
        if (ier.lt.KIM_STATUS_OK) then
           idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_set_data_f", ier)
           stop
        endif
     elseif (nbc.eq.3) then
        ier = kim_api_set_data_f(pkim, "get_neigh", SizeOne, loc(get_neigh_no_Rij))
        if (ier.lt.KIM_STATUS_OK) then
           idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_set_data_f", ier)
           stop
        endif
     elseif (nbc.eq.4) then
        ier = kim_api_set_data_f(pkim, "get_neigh", SizeOne, loc(get_neigh_Rij))
        if (ier.lt.KIM_STATUS_OK) then
           idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_set_data_f", ier)
           stop
        endif
     endif

     ! Initialize Model
     !
     ier = kim_api_model_init_f(pkim)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_model_init", ier)
        stop
     endif

     ! Unpack data from KIM object
     !
     call kim_api_getm_data_f(pkim, ier, &
          "numberOfParticles",           pnAtoms,           1,                    &
          "numberContributingParticles", pnumContrib,       TRUEFALSE(nbc.eq.0.or.nbc.eq.2),  &
          "numberParticleTypes",         pnparticleTypes,   1,                    &
          "particleTypes",               pparticleTypesdum, 1,                    &
          "coordinates",                 pcoor,             1,                    &
          "cutoff",                      pcutoff,           1,                    &
          "boxSideLengths",              pboxSideLengths,   TRUEFALSE(nbc.le.1),  &
          "energy",                      penergy,           1,                    &
          "forces",                      pforces,           1)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_getm_data_f", ier)
        stop
     endif
     call KIM_to_F90_int_array_1d(particleTypesdum, particleTypes, N)
     call KIM_to_F90_real_array_2d(coordum, coords, DIM, N)
     call KIM_to_F90_real_array_2d(forcesdum, forces, DIM, N)

     ! Set values in KIM object
     !
     numberOfParticles   = N
     if (nbc.eq.0.or.nbc.eq.2) numContrib = N
     numberParticleTypes = num_types
     do i=1,N
        particleTypes(i) = kim_api_get_partcl_type_code_f(pkim,trim(cluster_types(i)),ier)
     enddo
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_get_partcl_type_code_f", ier)
        stop
     endif
     do i=1,N
        coords(:,i) = cluster_coords(:,i)
     enddo
     if (nbc.le.1) boxSideLengths(:)  = 600.d0 ! large enough to make the cluster isolated

     ! Compute neighbor lists
     !
     if (nbc.le.4) then
        do_update_list = .true.
        allocate(coordsave(DIM,N))
        call update_neighborlist(DIM,N,coords,cutoff,cutpad,boxSideLengths,NBC_Method,  &
                                 do_update_list,coordsave,neighborList,RijList,ier)
        if (ier.lt.KIM_STATUS_OK) then
           idum = kim_api_report_error_f(__LINE__, __FILE__, "update_neighborlist", ier)
           stop
        endif
     endif
   
     ! Call model compute to get forces (gradient)
     !
     call kim_api_model_compute_f(pkim, ier)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_model_compute", ier)
        stop
     endif
   
     ! Turn off force computation
     !
     call kim_api_set_compute_f(pkim, "forces", 0, ier)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__,"kim_api_set_compute_f", ier)
        stop
     endif

     ! Compute gradient using numerical differentiation
     !
     allocate(forces_num(DIM,N),forces_num_err(DIM,N))
     do I=1,N
        do J=1,DIM
           call compute_numer_deriv(I,J,pkim,DIM,N,coords,cutoff,cutpad,   &
                                    boxSideLengths,NBC_Method,do_update_list,coordsave, &
                                    neighborList,RijList,deriv,deriv_err,ier)
           if (ier.lt.KIM_STATUS_OK) then
              idum = kim_api_report_error_f(__LINE__, __FILE__,"compute_numer_deriv", ier)
              stop
           endif
           forces_num(J,I) = -deriv
           forces_num_err(J,I) = deriv_err
        enddo
     enddo

     ! print results to screen
     !
     print '(41(''=''))'
     print '("NBC Method = ",A28)', NBC_Method(1:(index(NBC_Method,char(0))-1))
     print '(41(''=''))'
     print *
     print '(A6,2X,A4,2X,A3,2X,2A25,3A15,2X,A4)',"Atom","Type","Dir", "Force_model",   &
           "Force_numer",  "Force diff", "pred error", "weight",          &
           "stat"
     forcediff_sumsq = 0.d0
     weight_sum = 0.d0
     do I=1,N
        do J=1,DIM
           forcediff = abs(forces(J,I)-forces_num(J,I))
           if (forcediff<forces_num_err(J,I)) then
              passfail = "    "
           else
              passfail = "FAIL"
           endif
           weight = max(abs(forces_num(J,I)),eps_prec)/ &
                    max(abs(forces_num_err(J,I)),eps_prec)
           term = weight*forcediff**2
           if (term.gt.term_max) then
              term_max = term
              Imax = I
              Jmax = J
           endif
           forcediff_sumsq = forcediff_sumsq + term
           weight_sum = weight_sum + weight
           if (J.eq.1) then
              print '(I6,2X,I4,2X,I3,2X,2ES25.15,3ES15.5,2X,A4)', &
                     I,particleTypes(I),J,forces(J,I),forces_num(J,I), &
                     forcediff,forces_num_err(J,I),weight,passfail
           else
              print '(14X,I3,2X,2ES25.15,3ES15.5,2X,A4)', &
                     J,forces(J,I),forces_num(J,I), &
                     forcediff,forces_num_err(J,I),weight,passfail
           endif
        enddo
        print *
     enddo
     alpha = sqrt(forcediff_sumsq/weight_sum)/dble(DIM*N)
     print *
     print '("alpha = |Force_model - Force_numer|_w/(DIM*N) = ",ES15.5," (units of force)")', &
           alpha
     print *
     print '(''Maximum term obtained for Atom = '',I6,'', Dir = '',I1,&
        '', forcediff = '',ES15.5, '', forcediff/force_model = '',ES15.5)', &
        Imax,Jmax,abs(forces(Jmax,Imax)-forces_num(Jmax,Imax)),           &
        abs(forces(Jmax,Imax)-forces_num(Jmax,Imax))/abs(forces(Jmax,Imax))

     ! Free temporary storage
     ! 
     call free(pNBC_Method)
     deallocate(forces_num)
     deallocate(forces_num_err)
     if (nbc.le.4) then ! deallocate neighbor list storage
        deallocate(neighborList)
        deallocate(coordsave)
        if (nbc.eq.4) then
           deallocate(NLRvecLocs)
           deallocate(RijList)
        endif
     endif
     call kim_api_model_destroy_f(pkim, ier)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_model_destroy", ier)
        stop
     endif
     call kim_api_free(pkim, ier)
     if (ier.lt.KIM_STATUS_OK) then
        idum = kim_api_report_error_f(__LINE__, __FILE__, "kim_api_free", ier)
        stop
     endif

  enddo ! loop over NBC methods

  ! Print output footer
  !
  print *
  print '(120(''-''))'

  ! Free cluster storage
  !
  deallocate(cluster_coords,cluster_types)

  stop

end program TEST_NAME_STR