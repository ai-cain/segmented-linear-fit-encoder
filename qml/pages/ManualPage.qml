pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: page
    required property var theme
    required property var controller
    required property var navigateToPage

    property int inputMode: 0

    RowLayout {
        anchors.fill: parent
        spacing: 18

        Rectangle {
            Layout.preferredWidth: 390
            Layout.fillHeight: true
            radius: 22
            color: theme.panelAlt
            border.width: 1
            border.color: theme.border

            ScrollView {
                anchors.fill: parent
                anchors.margins: 18
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.availableWidth
                    spacing: 14

                    Label {
                        text: "Manual Input"
                        color: theme.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: page.inputMode === 0
                              ? "Generate evenly spaced X values from a minimum, maximum, and interval count."
                              : "Build a custom point list with free X/Y editing, add rows, and delete rows."
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 18
                        color: theme.field
                        border.width: 1
                        border.color: theme.fieldBorder
                        implicitHeight: modeCardLayout.implicitHeight + 28

                        ColumnLayout {
                            id: modeCardLayout
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Label {
                                text: "Input mode"
                                color: theme.textPrimary
                                font.bold: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                AppButton {
                                    Layout.fillWidth: true
                                    theme: page.theme
                                    primary: page.inputMode === 0
                                    text: "Range mode"
                                    onClicked: page.inputMode = 0
                                }

                                AppButton {
                                    Layout.fillWidth: true
                                    theme: page.theme
                                    primary: page.inputMode === 1
                                    text: "Custom points"
                                    onClicked: page.inputMode = 1
                                }
                            }
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        active: true
                        sourceComponent: page.inputMode === 0 ? rangeModeComponent : customModeComponent
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 18
                        color: theme.field
                        border.width: 1
                        border.color: theme.fieldBorder
                        implicitHeight: datasetCardLayout.implicitHeight + 28

                        ColumnLayout {
                            id: datasetCardLayout
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Label {
                                text: "Dataset"
                                color: theme.textPrimary
                                font.bold: true
                            }

                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                color: theme.textSecondary
                                text: controller.hasPoints
                                      ? controller.pointCount + " points available, " + controller.missingYCount + " Y values missing."
                                      : (page.inputMode === 0
                                         ? "No generated range yet."
                                         : "No custom points yet.")
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                AppButton {
                                    Layout.fillWidth: true
                                    theme: page.theme
                                    text: "Analyze"
                                    enabled: controller.hasPoints
                                    onClicked: {
                                        controller.runAnalysis()
                                        if (controller.hasResults)
                                            page.navigateToPage(2)
                                    }
                                }

                                AppButton {
                                    Layout.fillWidth: true
                                    theme: page.theme
                                    primary: false
                                    text: "Clear"
                                    enabled: controller.hasPoints
                                    onClicked: controller.clearPoints()
                                }
                            }
                        }
                    }
                }
            }
        }

        PointTablePanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            theme: page.theme
            controller: page.controller
            title: page.inputMode === 0 ? "Generated Points" : "Custom Points"
            subtitle: page.inputMode === 0
                      ? "X is generated from the selected range. Edit Y values row by row before analysis."
                      : "Edit X and Y freely, add rows from the left panel, and delete rows when needed. Keep X values in ascending order for best results."
            xEditable: page.inputMode === 1
            allowDelete: page.inputMode === 1
        }
    }

    Component {
        id: rangeModeComponent

        Rectangle {
            Layout.fillWidth: true
            radius: 18
            color: theme.field
            border.width: 1
            border.color: theme.fieldBorder
            implicitHeight: rangeLayout.implicitHeight + 28

            ColumnLayout {
                id: rangeLayout
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Label {
                    text: "Generate range"
                    color: theme.textPrimary
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    Label {
                        text: "Minimum"
                        color: theme.textSecondary
                    }

                    TextField {
                        id: minimumField
                        Layout.fillWidth: true
                        placeholderText: "0"
                        color: theme.textPrimary
                        selectByMouse: true
                        validator: DoubleValidator { }

                        background: Rectangle {
                            radius: 12
                            color: theme.panel
                            border.width: 1
                            border.color: theme.fieldBorder
                        }
                    }

                    Label {
                        text: "Maximum"
                        color: theme.textSecondary
                    }

                    TextField {
                        id: maximumField
                        Layout.fillWidth: true
                        placeholderText: "300"
                        color: theme.textPrimary
                        selectByMouse: true
                        validator: DoubleValidator { }

                        background: Rectangle {
                            radius: 12
                            color: theme.panel
                            border.width: 1
                            border.color: theme.fieldBorder
                        }
                    }

                    Label {
                        text: "Intervals"
                        color: theme.textSecondary
                    }

                    TextField {
                        id: intervalsField
                        Layout.fillWidth: true
                        placeholderText: "6"
                        color: theme.textPrimary
                        selectByMouse: true
                        validator: IntValidator { bottom: 1 }

                        background: Rectangle {
                            radius: 12
                            color: theme.panel
                            border.width: 1
                            border.color: theme.fieldBorder
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: theme.textSecondary
                    text: "Example: 0 to 300 with 6 intervals gives 7 evenly spaced X values."
                }

                AppButton {
                    Layout.fillWidth: true
                    theme: page.theme
                    text: "Generate points"
                    onClicked: controller.generatePoints(parseFloat(minimumField.text),
                                                         parseFloat(maximumField.text),
                                                         parseInt(intervalsField.text))
                }
            }
        }
    }

    Component {
        id: customModeComponent

        ColumnLayout {
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                radius: 18
                color: theme.field
                border.width: 1
                border.color: theme.fieldBorder
                implicitHeight: customSeedLayout.implicitHeight + 28

                ColumnLayout {
                    id: customSeedLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Label {
                        text: "Start from min / max"
                        color: theme.textPrimary
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: "Create two editable endpoint rows, then add any extra points you want between them."
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        Label {
                            text: "Minimum X"
                            color: theme.textSecondary
                        }

                        TextField {
                            id: customMinimumField
                            Layout.fillWidth: true
                            placeholderText: "0"
                            color: theme.textPrimary
                            selectByMouse: true
                            validator: DoubleValidator { }

                            background: Rectangle {
                                radius: 12
                                color: theme.panel
                                border.width: 1
                                border.color: theme.fieldBorder
                            }
                        }

                        Label {
                            text: "Maximum X"
                            color: theme.textSecondary
                        }

                        TextField {
                            id: customMaximumField
                            Layout.fillWidth: true
                            placeholderText: "300"
                            color: theme.textPrimary
                            selectByMouse: true
                            validator: DoubleValidator { }

                            background: Rectangle {
                                radius: 12
                                color: theme.panel
                                border.width: 1
                                border.color: theme.fieldBorder
                            }
                        }
                    }

                    AppButton {
                        Layout.fillWidth: true
                        theme: page.theme
                        text: "Create endpoints"
                        onClicked: controller.generatePoints(parseFloat(customMinimumField.text),
                                                             parseFloat(customMaximumField.text),
                                                             1)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 18
                color: theme.field
                border.width: 1
                border.color: theme.fieldBorder
                implicitHeight: customAddLayout.implicitHeight + 28

                ColumnLayout {
                    id: customAddLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Label {
                        text: "Add custom point"
                        color: theme.textPrimary
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: "Use this when you want irregular X spacing instead of exact interval steps."
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        Label {
                            text: "X value"
                            color: theme.textSecondary
                        }

                        TextField {
                            id: customXField
                            Layout.fillWidth: true
                            placeholderText: "125"
                            color: theme.textPrimary
                            selectByMouse: true
                            validator: DoubleValidator { }

                            background: Rectangle {
                                radius: 12
                                color: theme.panel
                                border.width: 1
                                border.color: theme.fieldBorder
                            }
                        }

                        Label {
                            text: "Y value"
                            color: theme.textSecondary
                        }

                        TextField {
                            id: customYField
                            Layout.fillWidth: true
                            placeholderText: "Optional"
                            color: theme.textPrimary
                            selectByMouse: true
                            validator: DoubleValidator { }

                            background: Rectangle {
                                radius: 12
                                color: theme.panel
                                border.width: 1
                                border.color: theme.fieldBorder
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        AppButton {
                            Layout.fillWidth: true
                            theme: page.theme
                            text: "Add point"
                            onClicked: {
                                if (controller.addPoint(customXField.text, customYField.text)) {
                                    customXField.clear()
                                    customYField.clear()
                                }
                            }
                        }

                        AppButton {
                            Layout.fillWidth: true
                            theme: page.theme
                            primary: false
                            text: "Sort by X"
                            enabled: controller.pointCount > 1
                            onClicked: controller.sortPointsByX()
                        }
                    }
                }
            }
        }
    }
}
