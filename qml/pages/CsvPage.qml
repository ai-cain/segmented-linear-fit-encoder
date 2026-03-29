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
                                  ? controller.pointCount + " points loaded, " + controller.missingYCount + " Y values missing."
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
        }
    }
}
