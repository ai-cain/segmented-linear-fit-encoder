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
                note: "current dataset"
                accentColor: theme.accent
            }

            MetricTile {
                Layout.fillWidth: true
                theme: page.theme
                label: "Segments"
                value: String(controller.segmentResults.length)
                note: controller.hasResults ? "computed" : "not available"
                accentColor: theme.success
            }

            MetricTile {
                Layout.fillWidth: true
                theme: page.theme
                label: "Missing Y"
                value: String(controller.missingYCount)
                note: "must be zero to analyze"
                accentColor: theme.info
            }
        }

        Rectangle {
            id: summaryCard
            Layout.fillWidth: true
            implicitHeight: summaryCardContent.implicitHeight + 36
            radius: 22
            color: theme.panelAlt
            border.width: 1
            border.color: theme.border

            ColumnLayout {
                id: summaryCardContent
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
                          : "Run the analysis from the CSV or Manual page to generate piecewise segments."
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 18

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18

                PlotPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360
                    theme: page.theme
                    controller: page.controller
                }

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
                            text: "Segments"
                            color: theme.textPrimary
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Loader {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            active: true
                            sourceComponent: controller.hasResults ? segmentsComponent : emptyComponent
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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Label {
                            Layout.fillWidth: true
                            text: "PLC Code"
                            color: theme.textPrimary
                            font.pixelSize: 22
                            font.bold: true
                        }

                        AppButton {
                            Layout.preferredWidth: 132
                            theme: page.theme
                            primary: false
                            text: "Copy PLC"
                            enabled: controller.hasResults
                            onClicked: controller.copyPlcCode()
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: "Generated from the computed piecewise segments."
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

    Component {
        id: emptyComponent

        Rectangle {
            radius: 18
            color: theme.field
            border.width: 1
            border.color: theme.fieldBorder

            Label {
                anchors.centerIn: parent
                text: "No segments yet."
                color: theme.textSecondary
                font.pixelSize: 16
            }
        }
    }

    Component {
        id: segmentsComponent

        Rectangle {
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
