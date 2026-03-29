cmake_minimum_required(VERSION 3.21)

project(PiecewiseLinearFit LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.5)
qt_policy(SET QTP0004 NEW)

qt_add_executable(PiecewiseLinearFit
    src/main.cpp
    src/AppController.cpp
    src/CodeExportService.cpp
    src/PointTableModel.cpp
    src/SegmentFitService.cpp
)

target_include_directories(PiecewiseLinearFit PRIVATE src)

target_link_libraries(PiecewiseLinearFit
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::QuickControls2
)

qt_add_qml_module(PiecewiseLinearFit
    URI PiecewiseLinearFit
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/AppButton.qml
        qml/components/MetricTile.qml
        qml/components/NavButton.qml
        qml/components/PointTablePanel.qml
        qml/components/PlotPanel.qml
        qml/pages/CsvPage.qml
        qml/pages/ManualPage.qml
        qml/pages/ResultsPage.qml
)

set_target_properties(PiecewiseLinearFit PROPERTIES
    OUTPUT_NAME "piecewise-linear-fit"
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

install(TARGETS PiecewiseLinearFit
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)
