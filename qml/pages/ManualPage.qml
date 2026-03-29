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

    RowLayout {
        anchors.fill: parent
        spacing: 18

        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            radius: 22
            color: theme.panelAlt
            border.width: 1
            border.color: theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
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
                    text: "Generate evenly spaced X values and then type the Y values in the table."
                }

                Rectangle {
                    id: generateCard
                    Layout.fillWidth: true
                    implicitHeight: generateCardContent.implicitHeight + 28
                    radius: 18
                    color: theme.field
                    border.width: 1
                    border.color: theme.fieldBorder

                    ColumnLayout {
                        id: generateCardContent
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
                                text: ""
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
                                text: ""
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
                                text: ""
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
                            text: "Example: 0 to 300 with 6 intervals gives 7 X values."
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

                Rectangle {
                    id: manualDatasetCard
                    Layout.fillWidth: true
                    implicitHeight: manualDatasetCardContent.implicitHeight + 28
                    radius: 18
                    color: theme.field
                    border.width: 1
                    border.color: theme.fieldBorder

                    ColumnLayout {
                        id: manualDatasetCardContent
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
                                  : "No manual range generated yet."
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

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        PointTablePanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            theme: page.theme
            controller: page.controller
        }
    }
}
