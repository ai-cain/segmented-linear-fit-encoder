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

    ColumnLayout {
        anchors.fill: parent
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MetricTile {
                Layout.fillWidth: true
                theme: page.theme
                label: "Points"
                value: String(controller.pointCount)
                note: "processed"
                accentColor: theme.accent
            }

            MetricTile {
                Layout.fillWidth: true
                theme: page.theme
                label: "Segments"
                value: String(controller.segmentResults.length)
                note: controller.hasResults ? "in the solution" : "not calculated"
                accentColor: theme.success
            }

            MetricTile {
                Layout.fillWidth: true
                theme: page.theme
                label: "Missing"
                value: String(controller.missingYCount)
                note: "Y values still missing"
                accentColor: theme.info
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 22
            color: theme.panelAlt
            border.width: 1
            border.color: theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Label {
                    text: "Summary"
                    color: theme.textPrimary
                    font.pixelSize: 22
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: theme.textSecondary
                    text: controller.hasResults
                          ? controller.summaryText
                          : "There are no results yet. Go to Data, complete the table, and run the analysis."
                }

                AppButton {
                    theme: page.theme
                    primary: false
                    text: "Back to data"
                    onClicked: page.navigateToPage(1)
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: true
            sourceComponent: controller.hasResults ? resultsComponent : emptyComponent
        }
    }

    Component {
        id: emptyComponent

        Rectangle {
            radius: 24
            color: theme.panelAlt
            border.width: 1
            border.color: theme.border

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 560)
                spacing: 12

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "There is no analysis to show yet."
                    color: theme.textPrimary
                    font.pixelSize: 28
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Once you finish loading or entering points, run the analysis from the Data page."
                    color: theme.textSecondary
                }

                AppButton {
                    Layout.alignment: Qt.AlignHCenter
                    theme: page.theme
                    text: "Go to data"
                    onClicked: page.navigateToPage(1)
                }
            }
        }
    }

    Component {
        id: resultsComponent

        RowLayout {
            spacing: 18

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 22
                color: theme.panelAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Label {
                        text: "Computed segments"
                        color: theme.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: theme.field
                        border.width: 1
                        border.color: theme.fieldBorder

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            spacing: 8
                            model: controller.segmentResults
                            ScrollBar.vertical: ScrollBar { }

                            delegate: Rectangle {
                                id: segmentCard
                                required property string title
                                required property string range
                                required property string equation
                                required property string rsquared

                                width: ListView.view ? ListView.view.width : 0
                                implicitHeight: infoLayout.implicitHeight + 24
                                radius: 16
                                color: "#111c31"
                                border.width: 1
                                border.color: theme.border

                                ColumnLayout {
                                    id: infoLayout
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    Label {
                                        text: segmentCard.title
                                        color: theme.accent
                                        font.pixelSize: 16
                                        font.bold: true
                                    }

                                    Label {
                                        text: segmentCard.range
                                        color: theme.textPrimary
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: segmentCard.equation
                                        color: theme.textPrimary
                                        font.family: "Consolas"
                                        font.pixelSize: 13
                                    }

                                    Label {
                                        text: segmentCard.rsquared
                                        color: theme.textSecondary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 420
                Layout.fillHeight: true
                radius: 22
                color: theme.panelAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Label {
                        text: "PLC code"
                        color: theme.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: "Automatically generated block based on the computed segments."
                    }

                    TextArea {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readOnly: true
                        wrapMode: TextArea.WrapAnywhere
                        text: controller.plcCode
                        color: theme.textPrimary
                        font.family: "Consolas"
                        font.pixelSize: 13
                        selectionColor: theme.accent
                        selectedTextColor: theme.bg

                        background: Rectangle {
                            radius: 18
                            color: theme.field
                            border.width: 1
                            border.color: theme.fieldBorder
                        }
                    }
                }
            }
        }
    }
}
