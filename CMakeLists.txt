# CMakeLists.txt for pdf22png
# Optional - to be implemented if CMake is chosen as an alternative build system.

# cmake_minimum_required(VERSION 3.10)
# project(pdf22png VERSION 1.0.0 LANGUAGES C OBJC)

# set(CMAKE_OBJC_STANDARD 11)
# set(CMAKE_OBJC_EXTENSIONS OFF)

# # macOS specific settings
# if(APPLE)
#     set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15" CACHE STRING "Minimum macOS deployment version")
#     set(CMAKE_OBJC_FLAGS "${CMAKE_OBJC_FLAGS} -fobjc-arc")
# endif()

# # Add source files
# set(SOURCES
#     src/pdf22png.m
#     src/utils.m
#     src/pdf22png.h
#     src/utils.h
# )

# add_executable(${PROJECT_NAME} ${SOURCES})

# # Link frameworks
# if(APPLE)
#     target_link_libraries(${PROJECT_NAME} PRIVATE
#         "-framework Foundation"
#         "-framework CoreGraphics" # Part of ApplicationServices or QuartzCore usually
#         "-framework AppKit"      # For some Quartz types if not covered by CoreGraphics alone
#         # "-framework ImageIO"   # For kUTTypePNG etc.
#     )
#     # More specific framework linking might be needed depending on exact symbols used.
#     # For example, CGPDFDocumentRef is in CoreGraphics.
#     # kUTTypePNG is in ImageIO (MobileCoreServices on iOS, CoreServices on macOS).
#     # AppKit includes many higher-level services. Foundation is for basic types.
#     find_library(FOUNDATION_FRAMEWORK Foundation)
#     find_library(COREGRAPHICS_FRAMEWORK CoreGraphics)
#     find_library(APPKIT_FRAMEWORK AppKit) # For NSApplication, NSWindow etc. Not strictly needed for CLI CG.
#                                          # Quartz might be -framework Quartz (includes CoreGraphics)
#     find_library(IMAGEIO_FRAMEWORK ImageIO)


#     if(FOUNDATION_FRAMEWORK AND COREGRAPHICS_FRAMEWORK AND IMAGEIO_FRAMEWORK)
#         target_link_libraries(${PROJECT_NAME} PRIVATE
#             "${FOUNDATION_FRAMEWORK}"
#             "${COREGRAPHICS_FRAMEWORK}"
#             "${IMAGEIO_FRAMEWORK}"
#             # Consider AppKit if any UI related symbols are pulled inadvertently, or if future GUI is planned
#             # "${APPKIT_FRAMEWORK}"
#         )
#     else()
#         message(WARNING "Could not find all required macOS Frameworks for linking.")
#     endif()

# endif()

# # Install target
# install(TARGETS ${PROJECT_NAME} DESTINATION bin)

# # Enable testing with CTest
# enable_testing()

# # Add tests (example)
# # add_test(NAME MyTest COMMAND MyTestRunner)
# # set_tests_properties(MyTest PROPERTIES WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

# message(STATUS "CMake configuration for pdf22png complete.")
