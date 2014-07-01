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
# Copyright (c) 2013--2014, Regents of the University of Minnesota.
# All rights reserved.
#
# Contributors:
#    Ryan S. Elliott
#    Valeriu Smirichinski
#    Ellad B. Tadmor
#

#
# Release: This file is part of the openkim-api.git repository.
#

ifeq ($(wildcard Makefile.KIM_Config),)
  $(error Makefile.KIM_Config does not exist.  Please create this file in order to compile the KIM API package)
endif
include Makefile.KIM_Config

export MODEL_DRIVERS_LIST := $(filter-out $(if $(wildcard $(KIM_MODEL_DRIVERS_DIR)/.kimignore),$(shell cat $(KIM_MODEL_DRIVERS_DIR)/.kimignore),),$(patsubst $(KIM_MODEL_DRIVERS_DIR)/%/,%,$(filter-out $(KIM_MODEL_DRIVERS_DIR)/,$(sort $(dir $(wildcard $(KIM_MODEL_DRIVERS_DIR)/*/))))))
export MODELS_LIST        := $(filter-out $(if $(wildcard $(KIM_MODELS_DIR)/.kimignore),$(shell cat $(KIM_MODELS_DIR)/.kimignore),),$(patsubst $(KIM_MODELS_DIR)/%/,%,$(filter-out $(KIM_MODELS_DIR)/,$(sort $(dir $(wildcard $(KIM_MODELS_DIR)/*/))))))
export TESTS_LIST         := $(filter-out $(if $(wildcard $(KIM_TESTS_DIR)/.kimignore),$(shell cat $(KIM_TESTS_DIR)/.kimignore),),$(patsubst $(KIM_TESTS_DIR)/%/,%,$(filter-out $(KIM_TESTS_DIR)/,$(sort $(dir $(wildcard $(KIM_TESTS_DIR)/*/))))))

KIM_CONFIG_FILES = $(KIM_DIR)/KIM_API/Makefile.KIM_Config $(KIM_MODEL_DRIVERS_DIR)/Makefile.KIM_Config $(KIM_MODELS_DIR)/Makefile.KIM_Config $(KIM_TESTS_DIR)/Makefile.KIM_Config

.PHONY: all models_check config \
            $(patsubst %,%-all,  $(MODELS_LIST) $(MODEL_DRIVERS_LIST) $(TESTS_LIST)) \
        clean kim-api-clean config-clean \
            $(patsubst %,%-clean,$(MODELS_LIST) $(MODEL_DRIVERS_LIST) $(TESTS_LIST)) \
        install install-check installdirs kim-api-objects-install kim-api-libs-install config-install \
            $(patsubst %,%-install,$(MODELS_LIST) $(MODEL_DRIVERS_LIST)) \
        uninstall kim-api-objects-uninstall kim-api-libs-uninstall config-uninstall \
        kim-api-objects kim-api-libs \
        examples examples-all \
        examples-force examples-force-all \
        examples-clean examples-clean-all

# compile everything in the standard directories
ifeq (dynamic-load,$(KIM_LINK))
   all: models_check config kim-api-objects kim-api-libs $(patsubst %,%-all,$(MODEL_DRIVERS_LIST) \
        $(MODELS_LIST)) $(patsubst %,%-all,$(TESTS_LIST))
else # everything else: dynamic-link static-link
   all: models_check config kim-api-objects $(patsubst %,%-all,$(MODEL_DRIVERS_LIST) $(MODELS_LIST)) \
        kim-api-libs $(patsubst %,%-all,$(TESTS_LIST))
endif

# other targets
clean: config $(patsubst %,%-clean,$(MODELS_LIST) $(MODEL_DRIVERS_LIST) $(TESTS_LIST)) kim-api-clean config-clean
ifeq (dynamic-load,$(KIM_LINK))
  install: install-check config kim-api-objects-install kim-api-libs-install $(patsubst %,%-install,$(MODEL_DRIVERS_LIST) $(MODELS_LIST)) config-install
else
  install: install-check config kim-api-objects-install $(patsubst %,%-install,$(MODEL_DRIVERS_LIST) $(MODELS_LIST)) kim-api-libs-install config-install
endif
uninstall: config kim-api-objects-uninstall kim-api-libs-uninstall config-uninstall
examples: config examples-all                    # copy examples to appropriate directories then make
examples-force: config examples-force-all
examples-clean: examples-clean-all

########### for internal use ###########
%-making-echo:
	@printf "\n%79s\n" " " | sed -e 's/ /*/g'
	@printf "%-77s%2s\n" "** Making... `printf "$(patsubst %-all,%,$*)" | sed -e 's/@/ /g'`" "**"
	@printf "%79s\n" " " | sed -e 's/ /*/g'

config: $(KIM_CONFIG_FILES)

Makefile:
	@touch Makefile

$(KIM_CONFIG_FILES): Makefile $(KIM_DIR)/Makefile.KIM_Config
	@printf "Creating... KIM_Config file..... $(patsubst $(KIM_DIR)/%,%,$@).\n";
	$(QUELL)printf "# This file is automatically generated by the KIM API make system.\n" > $@; \
                printf "# Do not edit!\n"                                                        >> $@; \
                printf "\n"                                                                      >> $@; \
                printf "include $(KIM_DIR)/Makefile.KIM_Config\n"                                >> $@;

config-clean:
	@printf "Cleaning... KIM_Config files.\n"
	$(QUELL)rm -f $(KIM_CONFIG_FILES)


install_makedir = $(dest_package_dir)/$(makedir)
install_make = Makefile.Generic Makefile.LoadDefaults Makefile.Model Makefile.ModelDriver Makefile.ParameterizedModel Makefile.SanityCheck Makefile.Test model_based_on_driver.cpp
install_compilerdir = $(dest_package_dir)/$(makecompilerdir)
install_compiler = Makefile.GCC Makefile.INTEL
install_linkerdir = $(dest_package_dir)/$(makelinkerdir)
install_linker = Makefile.DARWIN Makefile.FREEBSD Makefile.LINUX

install-check:
ifneq (dynamic-load,$(KIM_LINK))
	@if test -d "$(dest_package_dir)"; then \
        printf "*******************************************************************************\n"; \
        printf "*******               This package is already installed.                *******\n"; \
        printf "*******                 Please 'make uninstall' first.                  *******\n"; \
        printf "*******************************************************************************\n"; \
        false; else true; fi
else
        # should we check that the installed stuff is actually dynamic-load and the right settings (32bit, etc.)?
	$(QUELL)if test -d "$(dest_package_dir)"; then \
                  rm -rf "$(install_linkerdir)"; \
                  rm -rf "$(install_compilerdir)"; \
                  rm -rf "$(install_makedir)"; \
                  rm -f  "$(dest_package_dir)/Makefile.KIM_Config"; \
                  rm -f  "$(dest_package_dir)/Makefile.Version"; \
                fi
endif

installdirs:
ifeq (dynamic-load,$(KIM_LINK))
	$(QUELL)$(INSTALL_PROGRAM) -d -m 0755 "$(install_makedir)"
	$(QUELL)$(INSTALL_PROGRAM) -d -m 0755 "$(install_compilerdir)"
	$(QUELL)$(INSTALL_PROGRAM) -d -m 0755 "$(install_linkerdir)"
endif

config-install: installdirs
	@printf "Installing...($(dest_package_dir))................................. KIM_Config files"
ifeq (dynamic-load,$(KIM_LINK))
        # Install make directory
	$(QUELL)for fl in $(install_make); do $(INSTALL_PROGRAM) -m 0644 "$(makedir)/$$fl" "$(install_makedir)/$$fl"; done
#??????
	$(QUELL)printf ',s|^ *KIMINCLUDEFLAG *=.*|KIMINCLUDEFLAG = -I$$(KIM_DIR)/include|\nw\nq\n' | ed "$(install_makedir)/Makefile.Generic" > /dev/null 2>&1
	$(QUELL)printf ',s|/KIM_API||g\nw\nq\n' | ed "$(install_makedir)/Makefile.Generic" > /dev/null 2>&1
#??????
        # Install compiler defaults directory
	$(QUELL)for fl in $(install_compiler); do $(INSTALL_PROGRAM) -m 0644 "$(makecompilerdir)/$$fl" "$(install_compilerdir)/$$fl"; done
        # Install linker defaults directory
	$(QUELL)for fl in $(install_linker); do $(INSTALL_PROGRAM) -m 0644 "$(makelinkerdir)/$$fl" "$(install_linkerdir)/$$fl"; done
        # Install KIM_Config file
	$(QUELL)$(INSTALL_PROGRAM) -m 0644 Makefile.KIM_Config "$(dest_package_dir)/Makefile.KIM_Config"
	$(QUELL)fl="$(dest_package_dir)/Makefile.KIM_Config" && \
                printf 'g/KIM_MODEL_DRIVERS_DIR/d\nw\nq\n' | ed "$$fl" > /dev/null 2>&1 && \
                printf 'g/KIM_MODELS_DIR/d\nw\nq\n'        | ed "$$fl" > /dev/null 2>&1 && \
                printf 'g/KIM_TESTS_DIR/d\nw\nq\n'         | ed "$$fl" > /dev/null 2>&1 && \
                printf ',s|^ *KIM_DIR *=.*|KIM_DIR = $(dest_package_dir)|\nw\nq\n' | ed "$$fl" > /dev/null 2>&1
        # Install version file
	$(QUELL)$(INSTALL_PROGRAM) -m 0644 Makefile.Version "$(dest_package_dir)/Makefile.Version"
  ifeq (true,$(shell git rev-parse --is-inside-work-tree 2> /dev/null))
	$(QUELL)printf ',s|\$$(shell[^)]*).|$(shell git rev-parse --short HEAD)|\nw\nq\n' | ed "$(dest_package_dir)/Makefile.Version" > /dev/null 2>&1
  endif
	@printf ".\n"
else
	@printf ": nothing to be done for $(KIM_LINK).\n";
endif

install-set-default-to-v%: EXT:=$(if $(filter-out static-link,$(KIM_LINK)),so,a)
install-set-default-to-v%:
	@printf "Setting default $(package_name) to $(package_name)-v$*\n"
        # ignore the bin files at this stage (maybe add support for default bins later...)
	$(QUELL)fl="$(DESTDIR)$(includedir)/$(package_name)"       && if test -L "$$fl"; then rm -f "$$fl"; fi && ln -fs "$(package_name)-v$*" "$$fl"
	$(QUELL)fl="$(DESTDIR)$(libdir)/$(package_name)"           && if test -L "$$fl"; then rm -f "$$fl"; fi && ln -fs "$(package_name)-v$*" "$$fl"
	$(QUELL)fl="$(DESTDIR)$(libdir)/lib$(package_name).$(EXT)" && if test -L "$$fl"; then rm -f "$$fl"; fi && ln -fs "lib$(package_name)-v$*.$(EXT)" "$$fl"

uninstall-set-default: EXT:=$(if $(filter-out static-link,$(KIM_LINK)),so,a)
uninstall-set-default:
	@printf "Removing default $(package_name) settings.\n"
	$(QUELL)fl="$(DESTDIR)$(includedir)/$(package_name)"       && if test -L "$$fl"; then rm -f "$$fl"; fi
	$(QUELL)fl="$(DESTDIR)$(libdir)/$(package_name)"           && if test -L "$$fl"; then rm -f "$$fl"; fi
	$(QUELL)fl="$(DESTDIR)$(libdir)/lib$(package_name).$(EXT)" && if test -L "$$fl"; then rm -f "$$fl"; fi

config-uninstall:
	@printf "Uninstalling...($(dest_package_dir))................................. KIM_Config files.\n"
        # Make sure the package directory is gone
	$(QUELL)if test -d "$(dest_package_dir)"; then rm -rf "$(dest_package_dir)"; fi
        # Uninstall the rest
	$(QUELL)if test -d "$(DESTDIR)$(includedir)"; then rmdir "$(DESTDIR)$(includedir)" > /dev/null 2>&1 || true; fi
	$(QUELL)if test -d "$(DESTDIR)$(bindir)"; then rmdir "$(DESTDIR)$(bindir)" > /dev/null 2>&1 || true; fi
	$(QUELL)if test -d "$(DESTDIR)$(libdir)"; then rmdir "$(DESTDIR)$(libdir)" > /dev/null 2>&1 || true; fi
	$(QUELL)if test -d "$(DESTDIR)$(exec_prefix)"; then rmdir "$(DESTDIR)$(exec_prefix)" > /dev/null 2>&1 || true; fi
	$(QUELL)if test -d "$(DESTDIR)$(prefix)"; then rmdir "$(DESTDIR)$(prefix)" > /dev/null 2>&1 || true; fi

kim-api-objects: Makefile kim-api-objects-making-echo
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_DIR)/KIM_API/ objects

kim-api-libs: Makefile kim-api-libs-making-echo
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_DIR)/KIM_API/ libs

kim-api-clean:
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_DIR)/KIM_API/ clean
	$(QUELL)rm -f kim.log

kim-api-objects-install:
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_DIR)/KIM_API/ objects-install

kim-api-libs-install:
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_DIR)/KIM_API/ libs-install

kim-api-objects-uninstall:
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_DIR)/KIM_API/ objects-uninstall

kim-api-libs-uninstall:
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_DIR)/KIM_API/ libs-uninstall

examples-all:
	$(QUELL)$(foreach exmpl,$(notdir $(shell find $(KIM_DIR)/EXAMPLES/$(modeldriversdir) -maxdepth 1 -mindepth 1 \( -type d -o -type f \) -exec basename {} \;)),\
          if test -e $(KIM_MODEL_DRIVERS_DIR)/$(exmpl); then \
          printf "*@existing.....@%-50s@no@copy@performed!\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; else \
          printf "*@installing...@%-50s@copied@to@$(KIM_MODEL_DRIVERS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          cp -r $(KIM_DIR)/EXAMPLES/$(modeldriversdir)/$(exmpl) "$(KIM_MODEL_DRIVERS_DIR)/"; fi;)
	$(QUELL)$(foreach exmpl,$(notdir $(shell find $(KIM_DIR)/EXAMPLES/$(modelsdir) -maxdepth 1 -mindepth 1 \( -type d -o -type f \) -exec basename {} \;)),\
          if test -e $(KIM_MODELS_DIR)/$(exmpl); then \
          printf "*@existing.....@%-50s@no@copy@performed!\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; else \
          printf "*@installing...@%-50s@copied@to@$(KIM_MODELS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          cp -r $(KIM_DIR)/EXAMPLES/$(modelsdir)/$(exmpl) "$(KIM_MODELS_DIR)/"; fi;)
	$(QUELL)$(foreach exmpl,$(notdir $(shell find $(KIM_DIR)/EXAMPLES/TESTS -maxdepth 1 -mindepth 1 \( -type d -o -type f \) -exec basename {} \;)),\
          if test -e $(KIM_TESTS_DIR)/$(exmpl); then \
          printf "*@existing.....@%-50s@no@copy@performed!\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; else \
          printf "*@installing...@%-50s@copied@to@$(KIM_TESTS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          cp -r $(KIM_DIR)/EXAMPLES/TESTS/$(exmpl) "$(KIM_TESTS_DIR)/"; fi;)

examples-clean:
	@printf "Removing all installed example files...\n"
	$(QUELL)$(foreach dr,$(notdir $(wildcard $(KIM_DIR)/EXAMPLES/$(modeldriversdir)/*)), rm -rf "$(KIM_MODEL_DRIVERS_DIR)/$(dr)";)
	$(QUELL)$(foreach dr,$(notdir $(wildcard $(KIM_DIR)/EXAMPLES/$(modelsdir)/*)), rm -rf "$(KIM_MODELS_DIR)/$(dr)";)
	$(QUELL)$(foreach dr,$(notdir $(wildcard $(KIM_DIR)/EXAMPLES/TESTS/*)), rm -rf "$(KIM_TESTS_DIR)/$(dr)";)

examples-force-all:
	$(QUELL)$(foreach exmpl,$(notdir $(shell find $(KIM_DIR)/EXAMPLES/$(modeldriversdir) -maxdepth 1 -mindepth 1 \( -type d -o -type f \) -exec basename {} \;)),\
          if test -e $(KIM_MODEL_DRIVERS_DIR)/$(exmpl); then \
          printf "*@overwriting..@%-50s@copied@to@$(KIM_MODEL_DRIVERS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          rm -rf "$(KIM_MODEL_DRIVERS_DIR)/$(exmpl)"; \
          cp -r $(KIM_DIR)/EXAMPLES/$(modeldriversdir)/$(exmpl) "$(KIM_MODEL_DRIVERS_DIR)/"; else \
          printf "*@installing...@%-50s@copied@to@$(KIM_MODEL_DRIVERS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          cp -r $(KIM_DIR)/EXAMPLES/$(modeldriversdir)/$(exmpl) "$(KIM_MODEL_DRIVERS_DIR)/"; fi;)
	$(QUELL)$(foreach exmpl,$(notdir $(shell find $(KIM_DIR)/EXAMPLES/$(modelsdir) -maxdepth 1 -mindepth 1 \( -type d -o -type f \) -exec basename {} \;)),\
          if test -e $(KIM_MODELS_DIR)/$(exmpl); then \
          printf "*@overwriting..@%-50s@copied@to@$(KIM_MODELS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          rm -rf "$(KIM_MODELS_DIR)/$(exmpl)"; \
          cp -r $(KIM_DIR)/EXAMPLES/$(modelsdir)/$(exmpl) "$(KIM_MODELS_DIR)/"; else \
          printf "*@installing..@%-50s@copied@to@$(KIM_MODELS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          cp -r $(KIM_DIR)/EXAMPLES/$(modelsdir)/$(exmpl) "$(KIM_MODELS_DIR)/"; fi;)
	$(QUELL)$(foreach exmpl,$(notdir $(shell find $(KIM_DIR)/EXAMPLES/TESTS -maxdepth 1 -mindepth 1 \( -type d -o -type f \) -exec basename {} \;)),\
          if test -e $(KIM_TESTS_DIR)/$(exmpl); then \
          printf "*@overwriting..@%-50s@copied@to@$(KIM_TESTS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          rm -rf "$(KIM_TESTS_DIR)/$(exmpl)"; \
          cp -r $(KIM_DIR)/EXAMPLES/TESTS/$(exmpl) "$(KIM_TESTS_DIR)/"; else \
          printf "*@installing..@%-50s@copied@to@$(KIM_TESTS_DIR)\n" $(exmpl)@ | sed -e 's/ /./g' -e 's/@/ /g'; \
          cp -r $(KIM_DIR)/EXAMPLES/TESTS/$(exmpl) "$(KIM_TESTS_DIR)/"; fi;)

$(patsubst %,%-all,$(MODELS_LIST)): %: Makefile Model..........@%-making-echo | kim-api-objects
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_MODELS_DIR)/$(patsubst %-all,%,$@) all

$(patsubst %,%-clean,$(MODELS_LIST)):
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_MODELS_DIR)/$(patsubst %-clean,%,$@) clean

$(patsubst %,%-install,$(MODELS_LIST)):
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_MODELS_DIR)/$(patsubst %-install,%,$@) install

$(patsubst %,%-all,$(MODEL_DRIVERS_LIST)): %: Makefile Model@Driver...@%-making-echo | kim-api-objects
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_MODEL_DRIVERS_DIR)/$(patsubst %-all,%,$@) all

$(patsubst %,%-clean,$(MODEL_DRIVERS_LIST)):
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_MODEL_DRIVERS_DIR)/$(patsubst %-clean,%,$@) clean

$(patsubst %,%-install,$(MODEL_DRIVERS_LIST)):
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_MODEL_DRIVERS_DIR)/$(patsubst %-install,%,$@) install

$(patsubst %,%-all,$(TESTS_LIST)): %: Makefile Test...........@%-making-echo | kim-api-objects kim-api-libs $(patsubst %,%-all,$(MODELS_LIST))
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_TESTS_DIR)/$(patsubst %-all,%,$@) all

$(patsubst %,%-clean,$(TESTS_LIST)):
	$(QUELL)$(MAKE) $(MAKE_FLAGS) -C $(KIM_TESTS_DIR)/$(patsubst %-clean,%,$@) clean

models_check:
	@if test \( X"$(MODELS_LIST)" = X"" \) -a \( X"$(KIM_LINK)" = X"static-link" \); then     \
        printf "*******************************************************************************\n"; \
        printf "*******     Can't compile the API for static linking with no Models     *******\n"; \
        printf "*******              Maybe you want to do 'make examples'               *******\n"; \
        printf "*******************************************************************************\n"; \
        false; else true; fi
