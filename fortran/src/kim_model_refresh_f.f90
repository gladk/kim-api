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
! Copyright (c) 2016--2017, Regents of the University of Minnesota.
! All rights reserved.
!
! Contributors:
!    Ryan S. Elliott
!

!
! Release: This file is part of the kim-api.git repository.
!


module kim_model_refresh_f_module
  use, intrinsic :: iso_c_binding
  implicit none
  private

  public &
    kim_model_refresh_type, &
    set_influence_distance_pointer, &
    set_neighbor_list_cutoffs_pointer, &
    get_model_buffer_pointer, &
    log, &
    model_refresh_string

  type, bind(c) :: kim_model_refresh_type
    private
    type(c_ptr) :: p
  end type kim_model_refresh_type

  interface
    subroutine set_influence_distance_pointer(model_refresh, &
      influence_distance) &
      bind(c, name="KIM_ModelRefresh_SetInfluenceDistancePointer")
      use, intrinsic :: iso_c_binding
      import kim_model_refresh_type
      implicit none
      type(kim_model_refresh_type), intent(inout) :: &
        model_refresh
      type(c_ptr), intent(in), value :: influence_distance
    end subroutine set_influence_distance_pointer

    subroutine set_neighbor_list_cutoffs_pointer(model_refresh, &
      number_of_cutoffs, cutoffs_ptr) &
      bind(c, name="KIM_ModelRefresh_SetNeighborListCutoffsPointer")
      use, intrinsic :: iso_c_binding
      import kim_model_refresh_type
      implicit none
      type(kim_model_refresh_type), intent(inout) :: &
        model_refresh
      integer(c_int), intent(in), value :: number_of_cutoffs
      type(c_ptr), intent(in), value :: cutoffs_ptr
    end subroutine set_neighbor_list_cutoffs_pointer

    subroutine get_model_buffer_pointer(model_refresh, ptr) &
      bind(c, name="KIM_ModelRefresh_GetModelBufferPointer")
      use, intrinsic :: iso_c_binding
      import kim_model_refresh_type
      implicit none
      type(kim_model_refresh_type), intent(in) :: &
        model_refresh
      type(c_ptr), intent(out) :: ptr
    end subroutine get_model_buffer_pointer

    subroutine log(model_refresh, log_verbosity, message, &
      line_number, file_name) bind(c, name="KIM_ModelRefresh_Log")
      use, intrinsic :: iso_c_binding
      use kim_log_verbosity_module, only : kim_log_verbosity_type
      import kim_model_refresh_type
      implicit none
      type(kim_model_refresh_type), intent(in) :: &
        model_refresh
      type(kim_log_verbosity_type), intent(in), value :: log_verbosity
      character(c_char), intent(in) :: message(*)
      integer(c_int), intent(in), value :: line_number
      character(c_char), intent(in) :: file_name(*)
    end subroutine log

    type(c_ptr) function model_refresh_string(model_refresh) &
      bind(c, name="KIM_ModelRefresh_String")
      use, intrinsic :: iso_c_binding
      import kim_model_refresh_type
      implicit none
      type(kim_model_refresh_type), intent(in) :: &
        model_refresh
    end function model_refresh_string
  end interface
end module kim_model_refresh_f_module


! free functions to implement kim_model_refresh_module

logical function kim_model_refresh_handle_equal(left, right)
  use, intrinsic :: iso_c_binding
  use kim_model_refresh_module, only : kim_model_refresh_handle_type
  implicit none
  type(kim_model_refresh_handle_type), intent(in) :: left
  type(kim_model_refresh_handle_type), intent(in) :: right

  kim_model_refresh_handle_equal = c_associated(left%p, right%p)
end function kim_model_refresh_handle_equal

logical function kim_model_refresh_handle_not_equal(left, right)
  use, intrinsic :: iso_c_binding
  use kim_model_refresh_module, only : kim_model_refresh_handle_type
  use kim_model_refresh_module, only : operator (.eq.)
  implicit none
  type(kim_model_refresh_handle_type), intent(in) :: left
  type(kim_model_refresh_handle_type), intent(in) :: right

  kim_model_refresh_handle_not_equal = .not. (left .eq. right)
end function kim_model_refresh_handle_not_equal

subroutine kim_model_refresh_set_influence_distance_pointer( &
  model_refresh_handle, influence_distance)
  use, intrinsic :: iso_c_binding
  use kim_model_refresh_module, only : kim_model_refresh_handle_type
  use kim_model_refresh_f_module, only : kim_model_refresh_type, &
    set_influence_distance_pointer
  implicit none
  type(kim_model_refresh_handle_type), intent(inout) :: model_refresh_handle
  real(c_double), intent(in), target :: influence_distance
  type(kim_model_refresh_type), pointer :: model_refresh

  call c_f_pointer(model_refresh_handle%p, model_refresh)
  call set_influence_distance_pointer(model_refresh, &
    c_loc(influence_distance))
end subroutine kim_model_refresh_set_influence_distance_pointer

subroutine kim_model_refresh_set_neighbor_list_cutoffs_pointer( &
  model_refresh_handle, number_of_cutoffs, cutoffs)
  use, intrinsic :: iso_c_binding
  use kim_model_refresh_module, only : kim_model_refresh_handle_type
  use kim_model_refresh_f_module, only : kim_model_refresh_type, &
    set_neighbor_list_cutoffs_pointer
  implicit none
  type(kim_model_refresh_handle_type), intent(inout) :: model_refresh_handle
  integer(c_int), intent(in), value :: number_of_cutoffs
  real(c_double), intent(in), target :: cutoffs(number_of_cutoffs)
  type(kim_model_refresh_type), pointer :: model_refresh

  call c_f_pointer(model_refresh_handle%p, model_refresh)
  call set_neighbor_list_cutoffs_pointer(model_refresh, number_of_cutoffs, &
    c_loc(cutoffs))
end subroutine kim_model_refresh_set_neighbor_list_cutoffs_pointer

subroutine kim_model_refresh_get_model_buffer_pointer( &
  model_refresh_handle, ptr)
  use, intrinsic :: iso_c_binding
  use kim_model_refresh_module, only : kim_model_refresh_handle_type
  use kim_model_refresh_f_module, only : kim_model_refresh_type, &
    get_model_buffer_pointer
  implicit none
  type(kim_model_refresh_handle_type), intent(in) :: model_refresh_handle
  type(c_ptr), intent(out) :: ptr
  type(kim_model_refresh_type), pointer :: model_refresh

  call c_f_pointer(model_refresh_handle%p, model_refresh)
  call get_model_buffer_pointer(model_refresh, ptr)
end subroutine kim_model_refresh_get_model_buffer_pointer

subroutine kim_model_refresh_log(model_refresh_handle, &
  log_verbosity, message, line_number, file_name)
  use, intrinsic :: iso_c_binding
  use kim_model_refresh_module, only : kim_model_refresh_handle_type
  use kim_log_verbosity_module, only : kim_log_verbosity_type
  use kim_model_refresh_f_module, only : kim_model_refresh_type, log
  implicit none
  type(kim_model_refresh_handle_type), intent(in) :: model_refresh_handle
  type(kim_log_verbosity_type), intent(in), value :: log_verbosity
  character(len=*), intent(in) :: message
  integer(c_int), intent(in), value :: line_number
  character(len=*), intent(in) :: file_name
  type(kim_model_refresh_type), pointer :: model_refresh

  call c_f_pointer(model_refresh_handle%p, model_refresh)
  call log(model_refresh, log_verbosity, trim(message)//c_null_char, &
    line_number, trim(file_name)//c_null_char)
end subroutine kim_model_refresh_log

subroutine kim_model_refresh_string(model_refresh_handle, string)
  use, intrinsic :: iso_c_binding
  use kim_model_refresh_module, only : kim_model_refresh_handle_type
  use kim_model_refresh_f_module, only : kim_model_refresh_type, &
    model_refresh_string
  implicit none
  type(kim_model_refresh_handle_type), intent(in) :: model_refresh_handle
  character(len=*), intent(out) :: string
  type(kim_model_refresh_type), pointer :: model_refresh

  type(c_ptr) :: p
  character(len=len(string)+1), pointer :: fp
  integer(c_int) :: null_index

  call c_f_pointer(model_refresh_handle%p, model_refresh)
  p = model_refresh_string(model_refresh)
  call c_f_pointer(p, fp)
  null_index = scan(fp, char(0))-1
  string = fp(1:null_index)
end subroutine kim_model_refresh_string
