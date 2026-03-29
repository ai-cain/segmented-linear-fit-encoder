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
    required property var openCsvDialog

    RowLayout {
        anchors.fill: parent
        spacing: 18

        Rectangle {
            Layout.preferredWidth: 340
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
                    text: "CSV Import"
                    color: theme.textPrimary
                    font.pixelSize: 22
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: theme.textSecondary
                    text: "Use this page when you already have measured points saved in a CSV file."
                }

                Rectangle {
                    id: importCard
                    Layout.fillWidth: true
                    implicitHeight: importCardContent.implicitHeight + 28
                    radius: 18
                    color: theme.field
                    border.width: 1
                    border.color: theme.fieldBorder

                    ColumnLayout {
                        id: importCardContent
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Label {
                            text: "Import file"
                            color: theme.textPrimary
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: "The app reads the first two numeric columns as X and Y."
                        }

                        CheckBox {
                            Layout.fillWidth: true
                            visible: controller.csvHeadersAvailable
                            checked: controller.useCsvHeadersAsNames
                            text: "Use CSV header names in labels and exported code"
                            onToggled: controller.useCsvHeadersAsNames = checked

                            indicator: Rectangle {
                                implicitWidth: 18
                                implicitHeight: 18
                                x: parent.leftPadding
                                y: parent.topPadding + (parent.availableHeight - height) / 2
                                radius: 5
                                color: parent.checked ? theme.accent : theme.panel
                                border.width: 1
                                border.color: parent.checked ? theme.accent : theme.fieldBorder

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 3
                                    color: theme.bg
                                    visible: parent.parent.checked
                                }
                            }

                            contentItem: Text {
                                leftPadding: importNamesToggle.indicator.width + importNamesToggle.spacing
                                text: importNamesToggle.text
                                color: theme.textPrimary
                                font.pixelSize: 14
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                            }

                            id: importNamesToggle
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: controller.csvHeadersAvailable
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: controller.csvHeaderSummary
                        }

                        AppButton {
                            Layout.fillWidth: true
                            theme: page.theme
                            text: "Select CSV"
                            onClicked: page.openCsvDialog()
                        }
                    }
                }

                Rectangle {
                    id: datasetCard
                    Layout.fillWidth: true
                    implicitHeight: datasetCardContent.implicitHeight + 28
                    radius: 18
                    color: theme.field
                    border.width: 1
                    border.color: theme.fieldBorder

                    ColumnLayout {
                        id: datasetCardContent
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
                                  ? (controller.missingYCount === 0
                                     ? controller.pointCount + " points loaded, all " + controller.outputDisplayName + " values are available."
                                     : controller.pointCount + " points loaded, " + controller.missingYCount + " " + controller.outputDisplayName + " values missing.")
                                  : "No CSV loaded yet."
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
            xHeader: controller.inputDisplayName
            yHeader: controller.outputDisplayName
            subtitle: controller.useCsvHeadersAsNames
                      ? "The table is using the CSV header names for the X/Y labels and exported code."
                      : "The app is using generic X/Y labels. Enable the CSV header option on the left if you want the original names."
        }
    }
}
