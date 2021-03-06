# Check that people use the good file
if(NOT TOP_CMAKE_WAS_SOURCED)
    message(FATAL_ERROR "
    You did not 'cmake' the good CMakeLists.txt file. Use the one in the top dir.
    It is advice to delete all wrongly generated cmake stuff => CMakeFiles & CMakeCache.txt")
endif(NOT TOP_CMAKE_WAS_SOURCED)


# plugin name
set(Output onepad-1.1.0)

set(CommonFlags
    -fvisibility=hidden
    -Wall
    -std=c++0x
    )

set(OptimizationFlags
    -O2
    -DNDEBUG
    )

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    add_definitions(${CommonFlags} -g)
endif(CMAKE_BUILD_TYPE STREQUAL Debug)

if(CMAKE_BUILD_TYPE STREQUAL Devel)
	add_definitions(${CommonFlags} ${OptimizationFlags})
endif(CMAKE_BUILD_TYPE STREQUAL Devel)

if(CMAKE_BUILD_TYPE STREQUAL Release)
	add_definitions(${CommonFlags} ${OptimizationFlags})
endif(CMAKE_BUILD_TYPE STREQUAL Release)

if (SDL2_API)
    add_definitions(-DONEPAD_SDL2)
endif()

# onepad sources
set(onepadSources
	controller.cpp
	joystick.cpp
	keyboard.cpp
    KeyStatus.cpp
	onepad.cpp)

# onepad headers
set(onepadHeaders
	bitwise.h
	controller.h
	joystick.h
	keyboard.h
    KeyStatus.h
	onepad.h)

# onepad Linux sources
set(onepadLinuxSources
	Linux/ini.cpp
	Linux/dialog.cpp
	Linux/linux.cpp)

# onepad Linux headers
set(onepadLinuxHeaders
	Linux/linux.h)

# onepad Windows sources
set(onepadWindowsSources
	)

# onepad Windows headers
set(onepadWindowsHeaders
	)

# add additional include directories
include_directories(.)

# add library
add_library(${Output} SHARED
			${onepadSources}
			${onepadHeaders}
			${onepadLinuxSources}
			${onepadLinuxHeaders})

if (SDL2_API)
    target_link_libraries(${Output} ${SDL2_LIBRARY})
else()
    target_link_libraries(${Output} ${SDL_LIBRARY})
endif()

if(Linux)
	# link target with gtk2
	target_link_libraries(${Output} ${GTK2_LIBRARIES})
endif(Linux)

# link target with X11
target_link_libraries(${Output} ${X11_LIBRARIES})

# User flags options
if(NOT USER_CMAKE_LD_FLAGS STREQUAL "")
    target_link_libraries(${Output} "${USER_CMAKE_LD_FLAGS}")
endif(NOT USER_CMAKE_LD_FLAGS STREQUAL "")

if(PACKAGE_MODE)
    install(TARGETS ${Output} DESTINATION ${PLUGIN_DIR})
else(PACKAGE_MODE)
    install(TARGETS ${Output} DESTINATION ${CMAKE_SOURCE_DIR}/bin/plugins)
endif(PACKAGE_MODE)
