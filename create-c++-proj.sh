if [ -d "$1" ]; then
echo "Directory "$1" Already Exists"
else
if (( $# != 3 )); then
echo "Illegal number of parameters"
exit 1
fi
mkdir $1
mkdir $1/src
mkdir $1/cmake
cat << EOF > $1/ccls-setup.sh
cmake -H. -BDebug -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=YES
ln -s Debug/compile_commands.json .
EOF

cat << EOF > $1/CMakeLists.txt
cmake_minimum_required(VERSION 3.13)
project("$1")

set(PROJECT_VERSION_MAJOR 2)
set(PROJECT_VERSION_MINOR 0)
set(PROJECT_VERSION_PATCH 0)

set(CMAKE_CXX_STANDARD 17)
add_executable($1 src/main.cpp)

include_directories(include)

set(CMAKE_MODULE_PATH "\${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(Pack)
EOF
cat << EOF > $1/cmake/Pack.cmake
#TODO: Add rpm support
set(CPACK_PACKAGE_NAME \${PROJECT_NAME})

# which is useful in case of packing only selected components instead of the whole thing
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "$3")
set(CPACK_PACKAGE_VENDOR "$2")

set(CPACK_VERBATIM_VARIABLES YES)

set(CPACK_PACKAGE_INSTALL_DIRECTORY \${CPACK_PACKAGE_NAME})
set(CPACK_OUTPUT_FILE_PREFIX "\${CMAKE_SOURCE_DIR}/packages")

set(CPACK_PACKAGING_INSTALL_PREFIX "/usr/bin")

set(CPACK_PACKAGE_VERSION_MAJOR \${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR \${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH \${PROJECT_VERSION_PATCH})

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "$2")

set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>= 2.3.1-6), libgcc1 (>= 1:3.4.2-12), libstdc++6")

#set(CPACK_RESOURCE_FILE_LICENSE "\${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
#set(CPACK_RESOURCE_FILE_README "\${CMAKE_CURRENT_SOURCE_DIR}/README.md")

set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "\${CMAKE_SOURCE_DIR}/packages/deb/postinst")

# package name for deb
# if set, then instead of some-application-0.9.2-Linux.deb
# you'll get some-application_0.9.2_amd64.deb (note the underscores too)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
# if you want every group to have its own package,
# although the same happens if this is not sent (so it defaults to ONE_PER_GROUP)
# and CPACK_DEB_COMPONENT_INSTALL is set to YES
set(CPACK_COMPONENTS_GROUPING ALL_COMPONENTS_IN_ONE)#ONE_PER_GROUP)
# without this you won't be able to pack only specified component
set(CPACK_DEB_COMPONENT_INSTALL YES)

install(
    FILES
    "\${CMAKE_CURRENT_BINARY_DIR}/$1"
    DESTINATION "/usr/bin"
    COMPONENT \${PROJECT_NAME}
)
add_custom_target(run
    COMMAND "./$1"
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
include(CPack)
EOF
cat << EOF > $1/src/main.cpp
#include <iostream>

int main()
{
    std::cout << "Hello World" << std::endl;
}
EOF

chmod +x $1/ccls-setup.sh
cd $1
./ccls-setup.sh
cd ..
fi
