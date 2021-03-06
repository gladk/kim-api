#!/bin/sh
#

#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the Common Development
# and Distribution License Version 1.0 (the "License").
#
# You can obtain a copy of the license at
# http://www.opensource.org/licenses/CDDL-1.0.  See the License for the
# specific language governing permissions and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each file and
# include the License file in a prominent location with the name LICENSE.CDDL.
# If applicable, add the following below this CDDL HEADER, with the fields
# enclosed by brackets "[]" replaced with your own identifying information:
#
# Portions Copyright (c) [yyyy] [name of copyright owner]. All rights reserved.
#
# CDDL HEADER END
#

#
# Copyright (c) 2018, Regents of the University of Minnesota.
# All rights reserved.
#
# Contributors:
#    Ryan S. Elliott
#

#
# Release: This file is part of the kim-api.git repository.
#


_package_dir=###PACKAGE#DIR###
_sysconfdir=###SYSCONFDIR###
_full_package_name=###FULL#PACKAGE#NAME###

# Ensure that this script is sourced, not executed
if test x"`basename "$0" 2> /dev/null`" \
        = x"${_full_package_name}-activate"; then
  (>&2 printf "Error:\t${_full_package_name}-activate must be sourced.\n"
   printf "\tRun 'source ${_full_package_name}-activate' not "
   printf "'${_full_package_name}-activate'.\n")
  exit 1
fi

export PATH="${_package_dir}/bin:${PATH}"

source "${_sysconfdir}/bash_completion.d/${_full_package_name}-completion.bash"

unset _package_dir
unset _sysconfdir
unset _full_package_name
