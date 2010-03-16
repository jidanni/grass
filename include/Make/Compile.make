
# for i18N support
NLS_CFLAGS = -DPACKAGE=\"$(PACKAGE)\"

LINK = $(CC)

ifeq ($(MANIFEST),external)
PRELINK=$(MAKE) $@.manifest
else
ifeq ($(MANIFEST),internal)
PRELINK=$(MAKE) $(MANIFEST_OBJ)
else
PRELINK=:
endif
endif

linker_base = $(PRELINK) && $(1) $(2) -o $@ $(filter %.o,$^) $(filter %.res,$^) $(3)
linker_x = $(call linker_base,$(1),$(LDFLAGS) $(EXTRA_LDFLAGS),$(FMODE_OBJ) $(MANIFEST_OBJ) $(LIBES) $(EXTRA_LIBS) $(MATHLIB) $(XDRLIB))
linker_c = $(call linker_x,$(CC))
linker_cxx = $(call linker_x,$(CXX))
linker = $(call linker_x,$(LINK))

ALL_CFLAGS = $(LFS_CFLAGS) $(EXTRA_CFLAGS) $(NLS_CFLAGS) $(DEFS) $(EXTRA_INC) $(INC)

compiler_x = $(1) $(2) $(ALL_CFLAGS) -o $@ -c $<
compiler_c = $(call compiler_x,$(CC),$(COMPILE_FLAGS_C) $($*_c_FLAGS))
compiler_cxx = $(call compiler_x,$(CXX),$(COMPILE_FLAGS_CXX) $($*_cc_FLAGS) $($*_cpp_FLAGS) $($*_cxx_FLAGS))
compiler = $(call compiler_x,$(CC))

# default cc rules
$(OBJDIR)/%.o : %.c $(LOCAL_HEADERS) $(EXTRA_HEADERS) | $(OBJDIR)
	$(call compiler_c)

$(OBJDIR)/%.o : %.cc $(LOCAL_HEADERS) $(EXTRA_HEADERS) | $(OBJDIR)
	$(call compiler_cxx)

$(OBJDIR)/%.o : %.cpp $(LOCAL_HEADERS) $(EXTRA_HEADERS) | $(OBJDIR)
	$(call compiler_cxx)

# default parser generation rules, include prefix for files/vars
%.yy.c: %.l
	$(LEX) $(LFLAGS) -t $< > $@

%.output %.tab.h %.tab.c: %.y
	$(YACC) -b$* $(YFLAGS) $<

depend: $(C_SOURCES) $(CC_SOURCES) $(CPP_SOURCES)
	-$(CC) -E -MM -MG $(ALL_CFLAGS) $^ | sed 's!^[0-9a-zA-Z_.-]*\.o:!$$(OBJDIR)/&!' > $(DEPFILE)

%.manifest.res: %.manifest.rc %.exe.manifest
	$(WINDRES) --input=$< --input-format=rc --output=$@ --output-format=coff

%.manifest.rc:
	sed 's/@CMD@/$(notdir $*)/' $(MODULE_TOPDIR)/mswindows/generic.manifest.rc > $@

%.exe.manifest:
	sed 's/@CMD@/$(notdir $*)/' $(MODULE_TOPDIR)/mswindows/generic.manifest > $@

-include $(DEPFILE)
