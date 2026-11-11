# native/host — C Standalone host (loads Vyrn.dll via C ABI; no PureBasic)
cmake_minimum_required(VERSION 3.16)
project(vyrn_host C)

add_executable(vyrn_host vyrn_host.c)
target_include_directories(vyrn_host PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../include")

# Dynamic LoadLibrary / dlopen — do not link import lib.
if(WIN32)
  # Ensure console subsystem on MSVC.
  set_target_properties(vyrn_host PROPERTIES OUTPUT_NAME "VyrnHost")
else()
  set_target_properties(vyrn_host PROPERTIES OUTPUT_NAME "VyrnHost")
  target_link_libraries(vyrn_host PRIVATE dl)
endif()

install(TARGETS vyrn_host RUNTIME DESTINATION bin)
