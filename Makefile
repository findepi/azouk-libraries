
MAKEFLAGS	+= -r

PROGRAMS	:= server mxcontrol
LIBRARIES	:= 
SOURCEDIRS	:= azlib multiplexer mxcontrol-commands azouk
BUILDDIR	:= build

PYTHONFILES	:= $(shell find -name '*.py' | grep -v '\.svn' | sed -e 's@^\./@@' | grep -vE '^$(BUILDDIR)/') multiplexer/__init__.py
TARGETS		:= $(PYTHONFILES) multiplexer/multiplexer_constants.py azouk/logging/type_id_constants.py
GENERATE_CONSTANTS := build/generate_constants

default: all
.PHONY: default

ifeq "$V" ""
Q=@
else
Q=
endif

PYTHON_VERSION	:= 2.5
CXX		:= g++
GENERALFLAGS	+= -O3 -fstrict-aliasing -Wall -Wnon-virtual-dtor -Winit-self \
    			-Wswitch-enum -Wunused -Wunused-parameter \
			-DBOOST_DISABLE_THREADS \
			-Werror \
			#
CXXFLAGS	+= $(GENERALFLAGS) \
			-I . \
			-I $(BUILDDIR) \
			-I /usr/include/python$(PYTHON_VERSION) \
			-I $(BUILDDIR)/azlib \
			#
LDFLAGS		+= $(GENERALFLAGS) \
    			-lprotobuf \
			-lboost_program_options \
			-lboost_signals \
    			#
PYTHONMODULELDFLAGS	:= $(LDFLAGS) -lpython$(PYTHON_VERSION) -ldl -lpthread -lutil -lboost_python \

PROTOC		:= protoc
PROTOCFLAGS	:= 

# protocol buffers (http://code.google.com/apis/protocolbuffers/)
PROTOBUFS_FILES := $(shell find -name '*.proto' | grep -vE '/(\..*|build)' | sed -e 's@^\./@@g')
PROTOBUFS_COMPILATIONS_CC := $(PROTOBUFS_FILES:.proto=.pb.cc)
PROTOBUFS_COMPILATIONS_H := $(PROTOBUFS_FILES:.proto=.pb.h)
PROTOBUFS_COMPILATIONS_PY := $(PROTOBUFS_FILES:.proto=_pb2.py)
TARGETS := $(TARGETS) $(PROTOBUFS_COMPILATIONS_PY)
LIBRARIES := $(LIBRARIES) $(PROTOBUFS_COMPILATIONS_CC:.cc=.o)
LIBRARIES := $(LIBRARIES) $(shell for dir in $(SOURCEDIRS); do find $$dir -name '*.cc' | grep -v '\.svn' | sed -e 's/\.cc$$/.o/g'; done)

PROGRAMS			:= $(addprefix $(BUILDDIR)/,$(PROGRAMS))
TARGETS				:= $(addprefix $(BUILDDIR)/,$(TARGETS))
LIBRARIES			:= $(addprefix $(BUILDDIR)/,$(LIBRARIES))
PROTOBUFS_COMPILATIONS_CC	:= $(addprefix $(BUILDDIR)/,$(PROTOBUFS_COMPILATIONS_CC))
PROTOBUFS_COMPILATIONS_PY	:= $(addprefix $(BUILDDIR)/,$(PROTOBUFS_COMPILATIONS_PY))
PROTOBUFS_COMPILATIONS_H	:= $(addprefix $(BUILDDIR)/,$(PROTOBUFS_COMPILATIONS_H))
LINKLIBRARIES 			:= $(shell for i in $(LIBRARIES); do echo $$i; done | grep -vE 'module.o$$')
PYTHON_COMPILED_MODULES		:= $(shell for i in $(LIBRARIES); do echo $$i; done | grep -E 'module.o$$' | sed -e 's@module\.o$$@.so@')
TARGETS += $(PYTHON_COMPILED_MODULES) $(PROGRAMS)

$(PROTOBUFS_COMPILATIONS_CC) : $(BUILDDIR)/%.pb.cc : %.proto
	@ echo "Compiling protobufs file '$<' into '$@'"
	$Q mkdir -p `dirname $@`
	$Q rm -f $@
	$Q $(PROTOC) $(PROTOCFLAGS) -I . --cpp_out $(BUILDDIR) $<
	$Q test -f $@
	$Q chmod -x $@ $(shell echo `dirname $@`/`basename $@ .cc`.h)
# alias-like rule
$(PROTOBUFS_COMPILATIONS_H) : %.pb.h : %.pb.cc

$(PROTOBUFS_COMPILATIONS_PY) : $(BUILDDIR)/%_pb2.py : %.proto
	$Q mkdir -p `dirname $@`
	@ echo "Compiling protobufs file '$<' into '$@'"
	$Q rm -f $@
	$Q $(PROTOC) $(PROTOCFLAGS) -I . --python_out $(BUILDDIR) $<
	$Q test -f $@
	$Q chmod -x $@

SOURCE_FILES := $(shell find -name '*.cc' -o -name '*.c' | grep -v '\.svn') $(PROTOBUFS_COMPILATIONS_CC)
SOURCE_FILES := $(shell for i in $(SOURCE_FILES); do echo $$i; done | sed -e 's@^\./@@g')



# handling dependencies
DEPENDECY_FILES := $(shell for i in $(SOURCE_FILES); do echo $(BUILDDIR)/$$i.dep; done | sed -e 's@/\./@/@g' | sed -e 's@^build/build/@build/@g')

$(BUILDDIR)/%.dep: %
	@ echo "Creating dependency file for '$<'"
	$Q mkdir -p `dirname $@`
	$Q OBJECTFILE="$$(dirname $@)/$$(basename $@ .dep | sed -e 's@\.[a-z]\+$$@.o@')"; \
		$(CXX) $(CXXFLAGS) -MQ $$OBJECTFILE -MQ $@ -MM -MG -MP -o $@ $<
	$Q test -f $@

$(BUILDDIR)/%.dep: $(BUILDDIR)/%
	@ echo "Creating dependency file for '$<' (generated file)"
	$Q OBJECTFILE="$$(dirname $@)/$$(basename $@ .dep | sed -e 's@\.[a-z]\+$$@.o@')"; \
		$(CXX) $(CXXFLAGS) -MQ $$OBJECTFILE -MQ $@ -MM -MG -MP -o $@ $<
	$Q test -f $@

$(BUILDDIR)/%.dep:
	@ echo "Creating fake dependency file '$@'"
	$Q mkdir -p `dirname $@`
	$Q touch $@

ifneq "$(MAKECMDGOALS)" "clean"
ifneq "$(MAKECMDGOALS)" "sourcechanged"
-include $(DEPENDECY_FILES)
endif
endif

$(BUILDDIR)/multiplexer/__init__.py:
	touch $@

# generated header files
$(BUILDDIR)/multiplexer/multiplexer.constants.h $(BUILDDIR)/multiplexer/multiplexer_constants.py: multiplexer.rules $(GENERATE_CONSTANTS)
#	+@ [ "$$(bash -c 'test -t $(GENERATE_CONSTANTS)')" != "" ] || { echo "need ro remake $(GENERATE_CONSTANTS)" >/dev/null; $(MAKE) $(GENERATE_CONSTANTS); }
	$(GENERATE_CONSTANTS) $< $@

$(BUILDDIR)/azouk/logging/type_id_constants.py: logging.type_id.constants.txt
	$Q mkdir -p `dirname $@`
	cat $< > $@

$(BUILDDIR)/azouk/logging/type_id_constants.h: logging.type_id.constants.txt
	$Q mkdir -p `dirname $@`
	@ file_token=x`echo $@ | sha1sum | awk '{print $$1}'`; { set -e; \
		echo "#ifndef $$file_token"; \
		echo "#define $$file_token"; \
		echo "namespace `basename $@ .h | tr . _` {"; \
		cat $< | grep -v '^[ 	]*#' | grep -E . | sed -e 's/^\([a-zA-Z_]\+\) *= *\([0-9]\+[lL]\?\)/	static const unsigned int \1 = \2;/'; \
		echo "};"; \
		echo "#endif"; \
	    } > $@ || { rm -f $@; false; }

# copy the python files
$(BUILDDIR)/%.py: %.py
	@ echo "Copying '$@'"
	$Q mkdir -p `dirname $@`
	$Q cp -a $< $@

# compile to object file
$(BUILDDIR)/%.o: %.cc
	@ echo "Compiling '$@'"
	$Q mkdir -p `dirname $@`
	$Q $(CXX) -o $@ $< -c $(CXXFLAGS)

$(BUILDDIR)/%.o: $(BUILDDIR)/%.cc
	@ echo "Compiling '$@'"
	$Q $(CXX) -o $@ $< -c $(CXXFLAGS)

$(BUILDDIR)/lib__static_linklibraries.a: $(LINKLIBRARIES)
	@ echo "Packing '$@'"
	$Q ar rsu $@ $^

# shared libraries
$(BUILDDIR)/lib__linklibraries.so : $(LINKLIBRARIES)
# TODO(findepi) compile using lib__static_linklibraries.a
	@ echo "Linking '$@'"
	$Q $(CXX) -o $@ $(LINKLIBRARIES) -shared $(LDFLAGS)

$(filter-out $(BUILDDIR)/azouk/_allinone.so,$(PYTHON_COMPILED_MODULES)) : $(BUILDDIR)/%.so: $(BUILDDIR)/%module.o $(BUILDDIR)/lib__linklibraries.so
# TODO(findepi) use -l option to get dynamic linkage
# 		and determine $(BUILDDIR) absolute path reliably
	@ echo "Creating python module '$@'"
	$Q $(CXX) -o $@ `pwd`/$(BUILDDIR)/lib__linklibraries.so $< -shared $(PYTHONMODULELDFLAGS)

$(BUILDDIR)/azouk/_allinone.so : $(BUILDDIR)/%.so : $(BUILDDIR)/%module.o $(LINKLIBRARIES) \
    		$(BUILDDIR)/multiplexer/_mxclientmodule.o \
		$(BUILDDIR)/azouk/_loggingmodule.o
	@ echo "Creating python module '$@' with all libraries linked in"
	$Q $(CXX) -o $@ $^ -shared $(PYTHONMODULELDFLAGS)

$(BUILDDIR)/%.so: $(BUILDDIR)/%.o $(BUILDDIR)/lib__linklibraries.so
	@ echo "Creating '$@'"
	$Q $(CXX) -o $@ `pwd`/$(BUILDDIR)/lib__linklibraries.so $< -shared $(LDFLAGS)

# linking programs
$(PROGRAMS) : % : %.o $(BUILDDIR)/lib__static_linklibraries.a
	@ echo "Linking '$@'"
	$Q $(CXX) -o $@ $< $(LDFLAGS) $(LINKLIBRARIES)
#	$Q $(CXX) -o $@ $< $(LDFLAGS) $(BUILDDIR)/lib__static_linklibraries.a

$(GENERATE_CONSTANTS) : % : $(BUILDDIR)/multiplexer/Multiplexer.pb.o $(shell for i in $(LINKLIBRARIES); do echo $$i; done | grep /azlib/ ) %.o
	@ echo "Linking '$@'"
	$Q $(CXX) -o $@ $^ $(LDFLAGS)




# all, clean & other meta rules
all: $(TARGETS)
clean:
	- find -H $(BUILDDIR) -mindepth 1 -maxdepth 1 ! -name .gitignore | xargs rm -vrf

.PHONY: all clean default

sourcechanged: Makefile $(shell find -regextype posix-egrep -iregex '.*\.(cc|c|cpp|h|proto|py|rules)' | grep -vE '\.svn|build')
	@ touch $@

