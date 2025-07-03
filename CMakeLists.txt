# main_project/CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(main_project VERSION 1.0.0 LANGUAGES CXX)
include(CMakePrintHelpers)

# Either the following line or the set_target_properties with INSTALL_RPATH
# set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
# cmake_print_variables(ORIGIN)

# Search for lib_a
# find_package will look in CMAKE_PREFIX_PATH/lib/cmake/<PackageName>
# and CMAKE_PREFIX_PATH/<PackageName>/cmake/
find_package(lib_a CONFIG REQUIRED)

# Search for lib_b
find_package(lib_b CONFIG REQUIRED)

cmake_print_variables(CMAKE_INSTALL_PREFIX)# Add the executable target
add_executable(my_app main.cpp)

# Link the executable with the imported libraries
# The targets lib_a::lib_a and lib_b::lib_b are provided by the installed Config files
target_link_libraries(my_app PRIVATE
    lib_a::lib_a
    lib_b::lib_b
)

# Ensure include directories are added for the executable if not already handled by target_link_libraries
# For imported targets, their public include directories are usually propagated automatically,
# but it's good to explicitly add them if there's any doubt or if headers are used directly.
target_include_directories(my_app PRIVATE
    ${lib_a_INCLUDE_DIRS}
    ${lib_b_INCLUDE_DIRS}
)

# # Optional: Add rpath for development, not usually needed for installed executables
# set_target_properties(my_app PROPERTIES
#     BUILD_RPATH "$ORIGIN/../lib" # Linux/macOS
# )

# Set the RPATH for the installed executable
# This tells the executable where to find its shared libraries at runtime.
# $ORIGIN is a special linker variable on Linux/macOS that refers to the directory of the executable.
# So, $ORIGIN/../lib means "go up one directory from the executable, then into the 'lib' folder."
# This ensures that if 'my_app' is installed to 'bin', it will look for libs in the sibling 'lib' folder.
set_target_properties(my_app PROPERTIES
    INSTALL_RPATH "$ORIGIN/../lib" # Linux/macOS
)

install(IMPORTED_RUNTIME_ARTIFACTS
    lib_a::lib_a
    lib_b::lib_b
)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Install the executable
# This will copy 'my_app' to the 'bin' directory within the installation prefix
# install(TARGETS my_app DESTINATION bin)
install(TARGETS my_app
    EXPORT my_app_targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin # For Windows DLLs
)
