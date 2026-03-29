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

    ScrollView {
        id: homeScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: homeScroll.availableWidth
            spacing: 18

            Rectangle {
                id: heroCard
                Layout.fillWidth: true
                implicitHeight: heroContent.implicitHeight + 40
                radius: 24
                color: theme.panelAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: heroContent
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Label {
                        text: "From raw notebook to desktop app"
                        color: theme.accent
                        font.pixelSize: 12
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                    }

                    Label {
                        text: "The workflow is now split into pages so it feels more like a proper desktop tool."
                        color: theme.textPrimary
                        font.pixelSize: 30
                        font.bold: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: "Use Home to orient yourself, Data to load or generate points, and Results to review the final piecewise approximation and PLC code."
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        AppButton {
                            theme: page.theme
                            text: "Go to data"
                            onClicked: page.navigateToPage(1)
                        }

                        AppButton {
                            theme: page.theme
                            primary: false
                            text: "Open CSV"
                            onClicked: page.openCsvDialog()
                        }

                        AppButton {
                            theme: page.theme
                            primary: false
                            text: "View results"
                            onClicked: page.navigateToPage(2)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                MetricTile {
                    Layout.fillWidth: true
                    theme: page.theme
                    label: "Points"
                    value: String(controller.pointCount)
                    note: controller.hasPoints ? "ready to edit" : "not loaded yet"
                    accentColor: theme.accent
                }

                MetricTile {
                    Layout.fillWidth: true
                    theme: page.theme
                    label: "Missing"
                    value: String(controller.missingYCount)
                    note: "Y values still missing"
                    accentColor: theme.info
                }

                MetricTile {
                    Layout.fillWidth: true
                    theme: page.theme
                    label: "Segments"
                    value: String(controller.segmentResults.length)
                    note: controller.hasResults ? "calculated" : "no analysis yet"
                    accentColor: theme.success
                }
            }

            RowLayout {
                id: infoRow
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(inputsCard.implicitHeight, segmentsCard.implicitHeight)
                spacing: 18

                Rectangle {
                    id: inputsCard
                    Layout.fillWidth: true
                    implicitHeight: inputsContent.implicitHeight + 36
                    radius: 22
                    color: theme.panelAlt
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        id: inputsContent
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Label {
                            text: "Supported inputs"
                            color: theme.textPrimary
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: "1. CSV with two numeric columns. 2. Manual range using minimum, maximum, and intervals to distribute points and then fill in Y."
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: "The original notebook is still kept as a reference in files/segmented_linear_fit.ipynb."
                        }
                    }
                }

                Rectangle {
                    id: segmentsCard
                    Layout.fillWidth: true
                    implicitHeight: segmentsContent.implicitHeight + 36
                    radius: 22
                    color: theme.panelAlt
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        id: segmentsContent
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Label {
                            text: "Why piecewise"
                            color: theme.textPrimary
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: "When a single straight line does not represent the curve well enough, the analysis splits the relationship into consecutive segments and computes a different line for each range."
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: "That produces a much more useful output for PLC or embedded logic: IF / ELSIF ranges with simple equations."
                        }
                    }
                }
            }

            Rectangle {
                id: flowCard
                Layout.fillWidth: true
                implicitHeight: flowContent.implicitHeight + 36
                radius: 22
                color: theme.panelAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: flowContent
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Label {
                        text: "Recommended flow"
                        color: theme.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            "1. Go to Data and load a CSV or generate the manual range.",
                            "2. Fill in the missing Y values in the editable table.",
                            "3. Run the analysis and review the segment summary.",
                            "4. Open Results and copy or adapt the PLC block."
                        ]

                        delegate: Rectangle {
                            required property string modelData
                            Layout.fillWidth: true
                            radius: 16
                            color: theme.field
                            border.width: 1
                            border.color: theme.fieldBorder
                            implicitHeight: stepLabel.implicitHeight + 24

                            Label {
                                id: stepLabel
                                anchors.fill: parent
                                anchors.margins: 12
                                wrapMode: Text.WordWrap
                                text: modelData
                                color: theme.textPrimary
                            }
                        }
                    }
                }
            }
        }
    }
}
