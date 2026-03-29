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
    property int resultSection: 0
    property int fitChartMode: 0
    property int errorChartMode: 0

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

    function fitChartTitle() {
        switch (page.fitChartMode) {
        case 1:
            return "Measured Data Only"
        case 2:
            return "Piecewise Lines Only"
        default:
            return "Measured Data + Piecewise Fit"
        }
    }

    function fitChartSubtitle() {
        switch (page.fitChartMode) {
        case 1:
            return "Only the measured segmented points are shown."
        case 2:
            return "Only the fitted piecewise line segments are shown."
        default:
            return "Original segmented points together with the fitted lines for each segment."
        }
    }

    function fitChartSeries() {
        switch (page.fitChartMode) {
        case 1:
            return controller.segmentedPointSeries
        case 2:
            return controller.fittedLineSeries
        default:
            return page.mergeSeries(controller.segmentedPointSeries, controller.fittedLineSeries)
        }
    }

    function fitChartEmptyText() {
        switch (page.fitChartMode) {
        case 1:
            return "Run the analysis to see measured points only."
        case 2:
            return "Run the analysis to see the fitted piecewise lines."
        default:
            return "Run the analysis to see the combined fit."
        }
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

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: navigationLayout.implicitHeight + 36
                radius: 22
                color: theme.panelAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: navigationLayout
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Label {
                        text: "Result Views"
                        color: theme.textPrimary
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: theme.textSecondary
                        text: "Switch between the fitted curve, error diagnostics, and exportable results."
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        AppButton {
                            Layout.fillWidth: true
                            theme: page.theme
                            primary: page.resultSection === 0
                            text: "Fit Charts"
                            onClicked: page.resultSection = 0
                        }

                        AppButton {
                            Layout.fillWidth: true
                            theme: page.theme
                            primary: page.resultSection === 1
                            text: "Error Charts"
                            onClicked: page.resultSection = 1
                        }

                        AppButton {
                            Layout.fillWidth: true
                            theme: page.theme
                            primary: page.resultSection === 2
                            text: "Copy Results"
                            onClicked: page.resultSection = 2
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? implicitHeight : 0
                visible: page.resultSection !== 2
                implicitHeight: chartSectionLayout.implicitHeight + 36
                radius: 22
                color: theme.panelAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: chartSectionLayout
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Loader {
                        Layout.fillWidth: true
                        active: true
                        sourceComponent: page.resultSection === 0 ? fitChartsComponent : errorChartsComponent
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 460 : 0
                visible: page.resultSection === 2
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
        id: fitChartsComponent

        ColumnLayout {
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                AppButton {
                    Layout.fillWidth: true
                    theme: page.theme
                    primary: page.fitChartMode === 0
                    text: "Combined"
                    onClicked: page.fitChartMode = 0
                }

                AppButton {
                    Layout.fillWidth: true
                    theme: page.theme
                    primary: page.fitChartMode === 1
                    text: "Measured Only"
                    onClicked: page.fitChartMode = 1
                }

                AppButton {
                    Layout.fillWidth: true
                    theme: page.theme
                    primary: page.fitChartMode === 2
                    text: "Lines Only"
                    onClicked: page.fitChartMode = 2
                }
            }

            PlotPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 500
                theme: page.theme
                title: page.fitChartTitle()
                subtitle: page.fitChartSubtitle()
                xLabel: controller.inputDisplayName
                yLabel: controller.outputDisplayName
                showLegend: page.fitChartMode === 0
                seriesList: page.fitChartSeries()
                emptyText: page.fitChartEmptyText()
            }
        }
    }

    Component {
        id: errorChartsComponent

        ColumnLayout {
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                AppButton {
                    Layout.fillWidth: true
                    theme: page.theme
                    primary: page.errorChartMode === 0
                    text: "Global Residual"
                    onClicked: page.errorChartMode = 0
                }

                AppButton {
                    Layout.fillWidth: true
                    theme: page.theme
                    primary: page.errorChartMode === 1
                    text: "Segment Error"
                    onClicked: page.errorChartMode = 1
                }
            }

            PlotPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 510
                theme: page.theme
                title: page.errorChartMode === 0 ? "Residual vs Global Line" : "Segment Residual Error"
                subtitle: page.errorChartMode === 0
                          ? "Residuals computed against the notebook's single global line reference."
                          : "Per-segment residuals with the review tolerance band and out-of-range points highlighted."
                xLabel: controller.inputDisplayName
                yLabel: "Residual"
                chartHeight: page.errorChartMode === 0 ? 350 : 360
                showLegend: page.errorChartMode === 1
                seriesList: page.errorChartMode === 0
                            ? controller.globalResidualSeries
                            : page.mergeSeries(controller.segmentResidualSeries, controller.segmentErrorOutlierSeries)
                bandLower: page.errorChartMode === 1 ? -controller.reviewTolerance : 0
                bandUpper: page.errorChartMode === 1 ? controller.reviewTolerance : 0
                bandColor: "#2563eb"
                referenceLines: [{ "value": 0, "color": page.errorChartMode === 0 ? "#94a3b8" : "#cbd5e1", "width": 1.5 }]
                emptyText: page.errorChartMode === 0
                           ? "Run the analysis to inspect the global residuals."
                           : "Run the analysis to inspect segment error."
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
