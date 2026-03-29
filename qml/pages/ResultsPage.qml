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

    function mergeSeries(first, second) {
        const merged = []
        const left = first || []
        const right = second || []

        for (let i = 0; i < left.length; ++i)
            merged.push(left[i])
        for (let i = 0; i < right.length; ++i)
            merged.push(right[i])

        return merged
    }

    ScrollView {
        id: resultsScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: resultsScroll.availableWidth
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
                Layout.fillWidth: true
                implicitHeight: summaryLayout.implicitHeight + 36
                radius: 22
                color: theme.panelAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: summaryLayout
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
                              : "Run the analysis from the CSV or Manual page to generate all notebook-style charts."
                    }
                }
            }

            GridLayout {
                id: chartGrid
                Layout.fillWidth: true
                columns: width > 1280 ? 2 : 1
                columnSpacing: 18
                rowSpacing: 18

                PlotPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 430
                    theme: page.theme
                    title: "Measured Data + Piecewise Fit"
                    subtitle: "Original segmented points together with the fitted lines for each segment."
                    xLabel: controller.inputDisplayName
                    yLabel: controller.outputDisplayName
                    showLegend: false
                    seriesList: page.mergeSeries(controller.segmentedPointSeries, controller.fittedLineSeries)
                    emptyText: "Run the analysis to see the combined fit."
                }

                PlotPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 430
                    theme: page.theme
                    title: "Measured Data Only"
                    subtitle: "The same segmented data without the fitted lines."
                    xLabel: controller.inputDisplayName
                    yLabel: controller.outputDisplayName
                    seriesList: controller.segmentedPointSeries
                    emptyText: "Run the analysis to see segmented points."
                }

                PlotPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 430
                    theme: page.theme
                    title: "Piecewise Lines Only"
                    subtitle: "Final equations displayed as individual line segments."
                    xLabel: controller.inputDisplayName
                    yLabel: controller.outputDisplayName
                    seriesList: controller.fittedLineSeries
                    emptyText: "Run the analysis to see the fitted lines."
                }

                PlotPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 430
                    theme: page.theme
                    title: "Residual vs Global Line"
                    subtitle: "Residuals computed against the notebook's single global line reference."
                    xLabel: controller.inputDisplayName
                    yLabel: "Residual"
                    showLegend: false
                    seriesList: controller.globalResidualSeries
                    referenceLines: [{ "value": 0, "color": "#94a3b8", "width": 1.5 }]
                    emptyText: "Run the analysis to inspect the global residuals."
                }

                PlotPanel {
                    Layout.fillWidth: true
                    Layout.columnSpan: chartGrid.columns
                    Layout.preferredHeight: 440
                    theme: page.theme
                    title: "Segment Residual Error"
                    subtitle: "Per-segment residuals with the review tolerance band and out-of-range points highlighted."
                    xLabel: controller.inputDisplayName
                    yLabel: "Residual"
                    chartHeight: 340
                    seriesList: page.mergeSeries(controller.segmentResidualSeries, controller.segmentErrorOutlierSeries)
                    bandLower: -controller.reviewTolerance
                    bandUpper: controller.reviewTolerance
                    bandColor: "#2563eb"
                    referenceLines: [{ "value": 0, "color": "#cbd5e1", "width": 1.5 }]
                    emptyText: "Run the analysis to inspect segment error."
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 460
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

                Rectangle {
                    Layout.preferredWidth: 430
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
                                text: "Code Export"
                                color: theme.textPrimary
                                font.pixelSize: 22
                                font.bold: true
                            }

                            ComboBox {
                                id: exportTargetBox
                                Layout.preferredWidth: 160
                                model: controller.exportTargets
                                enabled: controller.hasResults
                                currentIndex: Math.max(0, controller.exportTargets.indexOf(controller.exportTarget))
                                onActivated: controller.exportTarget = currentText

                                contentItem: Text {
                                    leftPadding: 12
                                    rightPadding: exportTargetBox.indicator.width + exportTargetBox.spacing
                                    text: exportTargetBox.displayText
                                    font.pixelSize: 14
                                    color: theme.textPrimary
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                indicator: Canvas {
                                    x: exportTargetBox.width - width - 12
                                    y: exportTargetBox.topPadding + (exportTargetBox.availableHeight - height) / 2
                                    width: 12
                                    height: 8
                                    contextType: "2d"

                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.moveTo(0, 0)
                                        ctx.lineTo(width, 0)
                                        ctx.lineTo(width / 2, height)
                                        ctx.closePath()
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.fill()
                                    }
                                }

                                background: Rectangle {
                                    radius: 12
                                    color: theme.field
                                    border.width: 1
                                    border.color: theme.fieldBorder
                                }

                                popup: Popup {
                                    y: exportTargetBox.height + 6
                                    width: exportTargetBox.width
                                    implicitHeight: Math.min(contentItem.implicitHeight + 8, 220)
                                    padding: 4

                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: exportTargetBox.popup.visible ? exportTargetBox.delegateModel : null
                                        currentIndex: exportTargetBox.highlightedIndex
                                        ScrollIndicator.vertical: ScrollIndicator { }
                                    }

                                    background: Rectangle {
                                        radius: 12
                                        color: theme.panelAlt
                                        border.width: 1
                                        border.color: theme.border
                                    }
                                }

                                delegate: ItemDelegate {
                                    required property var modelData
                                    required property int index
                                    width: exportTargetBox.width - 8
                                    text: modelData
                                    highlighted: exportTargetBox.highlightedIndex === index

                                    contentItem: Text {
                                        text: parent.text
                                        color: theme.textPrimary
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        radius: 10
                                        color: parent.highlighted ? "#15243a" : "transparent"
                                    }
                                }
                            }

                            AppButton {
                                Layout.preferredWidth: 132
                                theme: page.theme
                                primary: false
                                text: "Copy Code"
                                enabled: controller.hasResults
                                onClicked: controller.copyExportCode()
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: theme.textSecondary
                            text: "Generated from the computed piecewise segments for " + controller.exportTarget + "."
                        }

                        ScrollView {
                            id: codeScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            background: Rectangle {
                                radius: 18
                                color: theme.field
                                border.width: 1
                                border.color: theme.fieldBorder
                            }

                            ScrollBar.horizontal: ScrollBar { }
                            ScrollBar.vertical: ScrollBar { }

                            TextArea {
                                id: exportCodeArea
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextArea.NoWrap
                                text: controller.exportCode
                                color: theme.textPrimary
                                font.family: "Consolas"
                                font.pixelSize: 13
                                selectionColor: theme.accent
                                selectedTextColor: theme.bg
                                padding: 16
                                width: Math.max(codeScroll.availableWidth, contentWidth + leftPadding + rightPadding)
                                height: Math.max(codeScroll.availableHeight, contentHeight + topPadding + bottomPadding)

                                background: null
                            }
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
