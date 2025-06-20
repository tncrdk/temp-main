# main_project/CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(main_project VERSION 1.0.0 LANGUAGES CXX)

# Search for lib_a
# find_package will look in CMAKE_PREFIX_PATH/lib/cmake/<PackageName>
# and CMAKE_PREFIX_PATH/<PackageName>/cmake/
find_package(lib_a CONFIG REQUIRED)

# Search for lib_b
find_package(lib_b CONFIG REQUIRED)

# Add the executable target
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

# Optional: Add rpath for development, not usually needed for installed executables
# set_target_properties(my_app PROPERTIES
#     BUILD_RPATH "$ORIGIN/../lib" # Linux/macOS
# )
