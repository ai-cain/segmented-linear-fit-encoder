pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "components"
import "pages"

ApplicationWindow {
    id: window
    width: 1480
    height: 920
    minimumWidth: 1220
    minimumHeight: 760
    visible: true
    visibility: Window.Maximized
    title: "Piecewise Linear Fit Studio"

    property int currentPage: 0
    readonly property var controller: appController

    QtObject {
        id: theme
        readonly property color bg: "#09111e"
        readonly property color panel: "#10192b"
        readonly property color panelAlt: "#0c1524"
        readonly property color border: "#24324b"
        readonly property color field: "#0d1727"
        readonly property color fieldBorder: "#2b3b58"
        readonly property color textPrimary: "#edf3ff"
        readonly property color textSecondary: "#98a7c4"
        readonly property color textMuted: "#6f819f"
        readonly property color accent: "#f97316"
        readonly property color accentStrong: "#ff5f0f"
        readonly property color accentSoft: "#fb923c"
        readonly property color success: "#22c55e"
        readonly property color info: "#38bdf8"
    }

    function openCsvDialog() {
        csvDialog.open()
    }

    function pageTitle(index) {
        switch (index) {
        case 0:
            return "CSV Import"
        case 1:
            return "Manual Input"
        case 2:
            return "Results"
        default:
            return "Piecewise Linear Fit Studio"
        }
    }

    function pageDescription(index) {
        switch (index) {
        case 0:
            return "Load measured points from a CSV file."
        case 1:
            return "Generate a range manually and fill in Y values."
        case 2:
            return "Inspect the piecewise fit, chart, and code output."
        default:
            return ""
        }
    }

    FileDialog {
        id: csvDialog
        title: "Select a CSV file"
        nameFilters: ["CSV (*.csv)", "Text (*.txt)", "All files (*)"]
        onAccepted: window.controller.loadCsv(selectedFile)
    }

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#08111e" }
            GradientStop { position: 1.0; color: "#0d1a31" }
        }

        Rectangle {
            x: -110
            y: -80
            width: 360
            height: 360
            radius: 180
            color: "#16355f"
            opacity: 0.22
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -80
            anchors.topMargin: 90
            width: 300
            height: 300
            radius: 150
            color: "#3b1f17"
            opacity: 0.22
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 18

        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            radius: 24
            color: theme.panel
            border.width: 1
            border.color: theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "PIECEWISE"
                        color: theme.accent
                        font.pixelSize: 12
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                    }

                    Label {
                        text: "Linear Fit Studio"
                        color: theme.textPrimary
                        font.pixelSize: 28
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: "Load points, run a piecewise fit, and inspect the final output."
                    }
                }

                Rectangle {
                    id: pagesCard
                    Layout.fillWidth: true
                    implicitHeight: pagesCardContent.implicitHeight + 28
                    radius: 18
                    color: theme.panelAlt
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        id: pagesCardContent
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Label {
                            text: "Pages"
                            color: theme.textPrimary
                            font.bold: true
                        }

                        NavButton {
                            Layout.fillWidth: true
                            theme: theme
                            text: "CSV Import"
                            subtitle: "Load measured points"
                            selected: window.currentPage === 0
                            onClicked: window.currentPage = 0
                        }

                        NavButton {
                            Layout.fillWidth: true
                            theme: theme
                            text: "Manual Input"
                            subtitle: "Generate and edit points"
                            selected: window.currentPage === 1
                            onClicked: window.currentPage = 1
                        }

                        NavButton {
                            Layout.fillWidth: true
                            theme: theme
                            text: "Results"
                            subtitle: "Chart and Code output"
                            selected: window.currentPage === 2
                            onClicked: window.currentPage = 2
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    id: statusCard
                    Layout.fillWidth: true
                    implicitHeight: statusCardContent.implicitHeight + 28
                    radius: 18
                    color: theme.panelAlt
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        id: statusCardContent
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Label {
                            text: "Status"
                            color: theme.textPrimary
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: window.controller.statusMessage.length > 0
                                  ? window.controller.statusMessage
                                  : "Ready."
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 26
            color: theme.panel
            border.width: 1
            border.color: theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(126, headerRow.implicitHeight + 32)
                    radius: 22
                    color: theme.panelAlt
                    border.width: 1
                    border.color: theme.border

                    RowLayout {
                        id: headerRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: window.pageTitle(window.currentPage)
                                color: theme.textPrimary
                                font.pixelSize: 30
                                font.bold: true
                            }

                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                color: theme.textSecondary
                                text: window.pageDescription(window.currentPage)
                            }
                        }

                        Rectangle {
                            id: datasetCard
                            Layout.preferredWidth: 300
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: datasetCardContent.implicitHeight + 24
                            radius: 18
                            color: theme.field
                            border.width: 1
                            border.color: theme.fieldBorder

                            ColumnLayout {
                                id: datasetCardContent
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 6

                                Label {
                                    text: "Current dataset"
                                    color: theme.textMuted
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.capitalization: Font.AllUppercase
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    color: theme.textPrimary
                                    text: window.controller.pointCount + " points loaded"
                                    font.pixelSize: 20
                                    font.bold: true
                                }

                                Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    color: theme.textSecondary
                                    text: window.controller.missingYCount === 0
                                          ? "All " + window.controller.outputDisplayName + " values are available"
                                          : window.controller.missingYCount + " " + window.controller.outputDisplayName + " values still missing"
                                }
                            }
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: window.currentPage

                    CsvPage {
                        theme: theme
                        controller: window.controller
                        navigateToPage: function(index) { window.currentPage = index }
                        openCsvDialog: function() { window.openCsvDialog() }
                    }

                    ManualPage {
                        theme: theme
                        controller: window.controller
                        navigateToPage: function(index) { window.currentPage = index }
                    }

                    ResultsPage {
                        theme: theme
                        controller: window.controller
                        navigateToPage: function(index) { window.currentPage = index }
                    }
                }
            }
        }
    }
}
