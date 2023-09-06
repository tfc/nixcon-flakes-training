cmake_minimum_required(VERSION 3.26)
project(cpp-project)

find_package(Boost REQUIRED)
find_package(Poco REQUIRED COMPONENTS Util)

add_executable(cpp-project src/main.cpp)
target_link_libraries(cpp-project ${Boost_LIBRARIES} Poco::Util)

install(TARGETS cpp-project DESTINATION bin)
