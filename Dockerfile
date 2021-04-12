FROM sirehna/base-image-win64-gcc540-win32threads

RUN mkdir -p /opt
WORKDIR /opt

RUN git clone https://github.com/google/protobuf.git protobuf_src && \
    cd protobuf_src && \
    git checkout v3.0.0-beta-2 && \
    mkdir cmake_build && \
    cd cmake_build && \
    cmake ../cmake \
        -Dprotobuf_BUILD_TESTS:BOOL=OFF \
        -Dprotobuf_BUILD_EXAMPLES:BOOL=OFF \
        -Dprotobuf_BUILD_PROTOC_BINARIES:BOOL=ON \
        -Dprotobuf_BUILD_SHARED_LIBS:BOOL=OFF \
        -Dprotobuf_WITH_ZLIB:BOOL=OFF \
        -DCMAKE_INSTALL_PREFIX=/opt/protobuf && \
    make && \
    make install && \
    cd .. && \
    cd .. && \
    rm -rf protobuf_src

RUN cd / && \
echo '\#!/bin/bash\n\
/usr/bin/wine /opt/protobuf/bin/protoc.exe `echo $*`\n'\
> /usr/bin/protoc && \
sed -i 's/\\#/#/g' /usr/bin/protoc && \
chmod 755 /usr/bin/protoc && \
cat /usr/bin/protoc && \
cd / && \
echo '\#!/bin/bash\n\
/usr/bin/wine /opt/protobuf/bin/protoc.exe `echo $*` 2> /dev/null\n'\
> /usr/bin/protoc_silent_error && \
sed -i 's/\\#/#/g' /usr/bin/protoc_silent_error && \
chmod 755 /usr/bin/protoc_silent_error && \
cat /usr/bin/protoc_silent_error

# libzmq
# Test program needs to be linked to ws_32 library.
# RUN find /usr/src/mxe/usr -name "*ws_32*" -type f && find /usr/src/mxe/usr -name "*wsock32*" -type f
# /usr/src/mxe/usr/x86_64-w64-mingw32.static/lib/libwsock32.a
RUN git clone https://github.com/zeromq/libzmq.git libzmq_src && \
    cd libzmq_src && \
    git checkout v4.2.2 && \
    mkdir build && \
    cd build && \
    cmake \
        -DWITH_PERF_TOOL=OFF \
        -DZMQ_BUILD_TESTS=OFF \
        -DENABLE_CPACK=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/libzmq \
        .. && \
    make && \
    echo "if(NOT TARGET libzmq) # in case find_package is called multiple times" >> ZeroMQConfig.cmake && \
    echo "  add_library(libzmq SHARED IMPORTED)" >> ZeroMQConfig.cmake && \
    echo "  set_target_properties(libzmq PROPERTIES IMPORTED_LOCATION \${\${PN}_LIBRARY})" >> ZeroMQConfig.cmake && \
    echo "endif(NOT TARGET libzmq)" >> ZeroMQConfig.cmake && \
    echo "" >> ZeroMQConfig.cmake && \
    echo "if(NOT TARGET libzmq-static) # in case find_package is called multiple times" >> ZeroMQConfig.cmake && \
    echo "  add_library(libzmq-static STATIC IMPORTED)" >> ZeroMQConfig.cmake && \
    echo "  set_target_properties(libzmq-static PROPERTIES IMPORTED_LOCATION \${\${PN}_STATIC_LIBRARY})" >> ZeroMQConfig.cmake && \
    echo "endif(NOT TARGET libzmq-static)" >> ZeroMQConfig.cmake && \
    make install && \
    # Patch CMake install files (Replace lib/libzmq.dll with bin\libzmq.dll)
    sed -i 's/lib\/libzmq\.dll/bin\/libzmq\.dll/g' /opt/libzmq/share/cmake/ZeroMQ/ZeroMQConfig.cmake && \
    cat /opt/libzmq/share/cmake/ZeroMQ/ZeroMQConfig.cmake && \
    cd .. && \
    cd .. && \
    rm -rf libzmq_src

RUN git clone https://github.com/zeromq/cppzmq.git cppzmq_src && \
    cd cppzmq_src && \
    git checkout v4.2.2 && \
    mkdir build && \
    cd build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/libzmq \
        -DZeroMQ_DIR:PATH=/opt/libzmq/share/cmake/ZeroMQ \
        .. && \
    make install && \
    cd .. && \
    cd .. && \
    rm -rf cppzmq_src

RUN cd /opt && \
    git clone https://github.com/garrison/eigen3-hdf5 && \
    cd eigen3-hdf5 && \
    git checkout 2c782414251e75a2de9b0441c349f5f18fe929a2

# HDF5 with C/C++/Fortran support Version 1.8.20. Higher versions are incompatible with eigen-hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/prev-releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar.gz -O hdf5_src.tar.gz && \
    mkdir -p HDF5_SRC && \
    tar -xf hdf5_src.tar.gz --strip 1 -C HDF5_SRC && \
    cd HDF5_SRC && \
    # Patch CMakeLists.txt to avoid warning message for each compiled file
    cp CMakeLists.txt CMakeListsORI.txt && \
    awk 'NR==3{print "ADD_DEFINITIONS(-DH5_HAVE_RANDOM=0)"}1' CMakeListsORI.txt > CMakeLists.txt && \
    # diff CMakeListsORI.txt CMakeLists.txt && \
    rm CMakeListsORI.txt && \
    # Patch src/CMakeLists.txt to work with wine when running a program while configuring/compiling
    cd src && \
    cp CMakeLists.txt CMakeListsORI.txt && \
    sed -i 's/COMMAND\ \${CMD}/COMMAND wine \${CMD}/g' CMakeLists.txt && \
    # diff CMakeListsORI.txt CMakeLists.txt && \
    cd .. && \
    # Patch fortran/src/CMakeLists.txt
    cd fortran && \
    cd src && \
    cp CMakeLists.txt CMakeListsORI.txt && \
    sed -i 's/COMMAND\ \${CMD}/COMMAND wine \${CMD}/g' CMakeLists.txt && \
    # diff CMakeListsORI.txt CMakeLists.txt && \
    cd .. && \
    cd .. && \
    # Patch hl/fortran/src/CMakeLists.txt
    cd hl && \
    cd fortran && \
    cd src && \
    cp CMakeLists.txt CMakeListsORI.txt && \
    sed -i 's/COMMAND\ \${CMD}/COMMAND wine \${CMD}/g' CMakeLists.txt && \
    # diff CMakeListsORI.txt CMakeLists.txt && \
    cd .. && \
    cd .. && \
    cd .. && \
    # Move back
    cd .. && \
    mkdir -p HDF5_build && \
    cd HDF5_build && \
    cmake \
      -DCMAKE_BUILD_TYPE:STRING=Release \
      -DCMAKE_INSTALL_PREFIX:PATH=/opt/HDF5_1_8_20 \
      -DBUILD_SHARED_LIBS:BOOL=ON \
      -DBUILD_TESTING:BOOL=OFF \
      -DHDF5_BUILD_EXAMPLES:BOOL=OFF \
      -DHDF5_BUILD_HL_LIB:BOOL=ON \
      -DHDF5_BUILD_CPP_LIB:BOOL=ON \
      -DHDF5_BUILD_FORTRAN:BOOL=ON \
      ../HDF5_SRC && \
    # Patch cmake files
    # http://hdf-forum.184993.n3.nabble.com/Compilation-of-HDF5-1-10-1-with-MSYS-and-MiNGW-td4029696.html
    # sed -i 's/\r//g' H5config_f.inc && \
    # sed -i 's/\r//g' fortran/H5fort_type_defines.h && \
    make && \
    # Fixed Fortran mod install bug
    mkdir -p bin/static/Release && \
    cp bin/static/*.mod bin/static/Release/. && \
    make install && \
    cd .. && \
    rm -rf HDF5_build && \
    rm -rf HDF5_SRC && \
    rm -rf hdf5_src.tar.gz

RUN cd /opt && \
    wget https://gitlab.com/sirehna_naval_group/ssc/ssc/-/jobs/artifacts/v9.0.1/download?job=Windows+64+bits+with+GCC+5.4.0+win32+threads -O artifacts.zip && \
    unzip artifacts.zip && \
    rm artifacts.zip && \
    mkdir ssc && \
    cd ssc && \
    unzip ../ssc.zip && \
    cd .. && \
    rm -rf ssc.zip
