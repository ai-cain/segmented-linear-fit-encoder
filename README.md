# Segmented Linear Fit Encoder

Qt 6 + C++ desktop application for building a piecewise linear approximation from measured data.

The current app is shipped as `Piecewise Linear Fit Studio` and supports:

- CSV import
- manual point generation
- editable point tables
- piecewise linear analysis
- residual review charts
- code export for PLC, Python, C++, JavaScript, Java, and C#

## Project Flow

```mermaid
flowchart LR
    A[CSV or Manual Input] --> B[PointTableModel]
    B --> C[SegmentFitService]
    C --> D[Segment results]
    D --> E[Charts in QML]
    D --> F[CodeExportService]
    F --> G[PLC and code output]
```

## Documentation

Full project documentation is available in [`docs/README.md`](./docs/README.md).

It covers:

- architecture
- data flow
- segmentation algorithm
- chart generation
- export behavior
- relationship with the legacy notebook

## Screenshots

### CSV Import

![CSV Import](docs/img/01_csv_import.png)

### Manual Input

**Range mode**

![Manual Input Range](docs/img/02_01_manual_input_range.png)

**Custom points mode**

![Manual Input Custom](docs/img/02_01_manual_input_custom.png)

### Results

**Piecewise fit chart**

![Results Chart](docs/img/03_01_results_chart.png)

**Global residual view**

![Global Residual](docs/img/03_02_results_global_residual.png)

**Segment error review**

![Segment Error](docs/img/03_03_results_segment_error.png)

**Code export**

![Code Export](docs/img/03_04_code_copy.png)

## Open In Qt Creator

Open `CMakeLists.txt`, not `.pro` or `.pyproject`.

## Build On Windows With Qt

```powershell
C:\Qt\6.10.2\llvm-mingw_64\bin\qt-cmake.bat -S . -B build-cpp-qt -G Ninja -DCMAKE_MAKE_PROGRAM=C:/Qt/Tools/Ninja/ninja.exe -DCMAKE_CXX_COMPILER=C:/Qt/Tools/llvm-mingw1706_64/bin/clang++.exe
C:\Qt\Tools\Ninja\ninja.exe -C build-cpp-qt
C:\Qt\6.10.2\llvm-mingw_64\bin\windeployqt.exe --qmldir qml build-cpp-qt\piecewise-linear-fit.exe
```

Expected executable:

- `build-cpp-qt/piecewise-linear-fit.exe`

## Repository Layout

- `src/`: C++ backend
- `qml/`: Qt Quick UI
- `files/`: sample CSV files and the legacy notebook
- `docs/`: project documentation

## Sample Files

- `files/data1_length.csv`
- `files/data2_length.csv`
- `files/segmented_linear_fit.ipynb`
