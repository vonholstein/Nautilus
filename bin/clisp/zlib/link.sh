files='zlib.o'
${MAKE-make} clisp-module \
  CC="${CC}" CPPFLAGS="${CPPFLAGS}" CFLAGS="${CFLAGS}" \
  INCLUDES="$absolute_linkkitdir"
NEW_FILES="${files}"
NEW_LIBS="${files} -lz"
NEW_MODULES="zlib"
TO_LOAD='zlib'
