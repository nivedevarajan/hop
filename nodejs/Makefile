#*=====================================================================*/
#*    serrano/prgm/project/hop/2.6.x/nodejs/Makefile                   */
#*    -------------------------------------------------------------    */
#*    Author      :  Manuel Serrano                                    */
#*    Creation    :  Wed Apr  1 18:45:46 1998                          */
#*    Last change :  Fri Feb 14 11:50:15 2014 (serrano)                */
#*    -------------------------------------------------------------    */
#*    The makefile to build the NODEJS library.                        */
#*=====================================================================*/
.PHONY: do 

do: build

#*---------------------------------------------------------------------*/
#*    Standard Hop configuration                                       */
#*---------------------------------------------------------------------*/
-include ../etc/Makefile.hopconfig
-include ../etc/Makefile.version
-include $(BIGLOOLIBDIR)/Makefile.config

#*---------------------------------------------------------------------*/
#*    Compilers, Tools and Destinations                                */
#*---------------------------------------------------------------------*/
# the library name
TARGETNAME = nodejs
HOPCLOSELIBS_S = $(BGLCLOSELIBS_S) \
  -ljs2scheme_s-$(HOPRELEASE) -lhopscript_s-$(HOPRELEASE) 
HOPCLOSELIBS_U = $(BGLCLOSELIBS_U) \
  -ljs2scheme_u-$(HOPRELEASE) -lhopscript_u-$(HOPRELEASE) 
HOPCLOSELIBS_ES = $(BGLCLOSELIBS_ES) \
  -ljs2scheme_s-$(HOPRELEASE) -lhopscript_s-$(HOPRELEASE) 
HOPCLOSELIBS_EU = $(BGLCLOSELIBS_EU) \
  -ljs2scheme_u-$(HOPRELEASE) -lhopscript_u-$(HOPRELEASE) 

BLIBFLAGS = $(BCFLAGSRTS)

#*---------------------------------------------------------------------*/
#*    Scheme extended objects                                          */
#*---------------------------------------------------------------------*/
_OBJECTS = nodejs require process repl
_JS_OBJECTS = console constants util sys path stream events fs \
  punycode assert buffer dgram net timers vm querystring cluster \
  child_process string_decoder _linklist _stream_readable _stream_writable \
  _stream_duplex _stream_transform _stream_passthrough crypto dns domain \
  freelist http https tls zlib url

OBJECTS = $(_OBJECTS:%=o/%.o) $(_JS_OBJECTS:%=o/%.o)
EOBJECTS = o/make_lib.o

BGL_CLASSES = $(_OBJECTS:%=$(CLASS_DIR)/%.class)
BGL_ECLASSES = $(CLASS_EDIR)/make_lib.class

SOURCES = $(_OBJECTS:%=%.scm) $(_JS_OBJECTS:%=%.js)

INCLUDES = 

#*---------------------------------------------------------------------*/
#*    Sources                                                          */
#*---------------------------------------------------------------------*/
POPULATION = $(SOURCES) $(INCLUDES) make_lib.scm Makefile

include ../etc/Makefile.library

#*---------------------------------------------------------------------*/
#*    all                                                              */
#*---------------------------------------------------------------------*/
.PHONY: build native jvm

build:
	(LD_LIBRARY_PATH=$(BUILDLIBDIR):$$LD_LIBRARY_PATH; \
         export LD_LIBRARY_PATH; \
         DYLD_LIBRARY_PATH=$(BUILDLIBDIR):$$DYLD_LIBRARY_PATH; \
         export DYLD_LIBRARY_PATH; \
         PATH=$(BUILDBINDIR):$(BUILDLIBDIR):$$PATH; \
         export PATH; \
	 $(MAKE) $(BACKEND))

native: heap-c lib-c
jvm: heap-jvm lib-jvm

#*---------------------------------------------------------------------*/
#*    Suffixes                                                         */
#*---------------------------------------------------------------------*/
.SUFFIXES: .js

#*---------------------------------------------------------------------*/
#*    The implicit rules                                               */
#*---------------------------------------------------------------------*/
o/js/%.scm: %.js $(HEAP_FILE)
	@ $(call compile3,$(HOPC),$(HFLAGS),$(BCFLAGS),$(BLFLAGS) $(EFLAGS) $(HEFLAGS),-s,$< -o $@)

$(_JS_OBJECTS:%=o/%.o): $(HEAP_FILE)

#*---------------------------------------------------------------------*/
#*    ude                                                              */
#*---------------------------------------------------------------------*/
.PHONY: ude
ude:
	@ $(MAKE) -f Makefile .afile .etags .jfile
	@ $(MAKE) dep

.afile: $(SOURCES)
	@ $(AFILE) -suffix hop -o .afile $(filter %.scm, $(SOURCES))

.jfile: $(SOURCES)
	@ $(JFILE) -suffix hop -o .jfile \
                   -pbase $(PBASE) $(SOURCES) make_lib.scm

.etags: $(SOURCES) $(INCLUDES)
	@ $(BTAGS) -o .etags $(SOURCES) $(INCLUDES)

getsources:
	@ echo $(SOURCES)

#*---------------------------------------------------------------------*/
#*    Explicit dependencies                                            */
#*---------------------------------------------------------------------*/

#bdepend start (don't edit)
#*---------------------------------------------------------------------*/
#*    Dependencies ...                                                 */
#*---------------------------------------------------------------------*/


#bdepend stop