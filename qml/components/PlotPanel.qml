pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: panel
    required property var theme
    required property var controller
    readonly property string plotBackgroundColor: "#0d1727"
    readonly property string plotBorderColor: "#2b3b58"
    readonly property string plotGridColor: "#20314c"
    readonly property string plotTextColor: "#98a7c4"
    readonly property string plotPointColor: "#38bdf8"
    readonly property string plotLineColor: "#f97316"

    radius: 22
    color: theme.panelAlt
    border.width: 1
    border.color: theme.border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Label {
            text: "Chart"
            color: theme.textPrimary
            font.pixelSize: 22
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: theme.textSecondary
            text: controller.hasResults
                  ? "Measured points with the computed piecewise line."
                  : "Measured points preview. The fitted segments appear after analysis."
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 18
            color: theme.field
            border.width: 1
            border.color: theme.fieldBorder

            Canvas {
                id: canvas
                anchors.fill: parent
                anchors.margins: 12
                antialiasing: true
                renderTarget: Canvas.Image

                Component.onCompleted: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                Connections {
                    target: controller
                    function onPointsChanged() { canvas.requestPaint() }
                    function onResultsChanged() { canvas.requestPaint() }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const width = canvas.width
                    const height = canvas.height
                    ctx.clearRect(0, 0, width, height)

                    const left = 56
                    const right = 24
                    const top = 20
                    const bottom = 40
                    const drawWidth = Math.max(1, width - left - right)
                    const drawHeight = Math.max(1, height - top - bottom)

                    ctx.fillStyle = panel.plotBackgroundColor
                    ctx.fillRect(0, 0, width, height)

                    const points = controller.pointSeries
                    const segments = controller.segmentResults

                    if (points.length === 0) {
                        ctx.fillStyle = panel.plotTextColor
                        ctx.font = "16px sans-serif"
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.fillText("No chart data yet", width / 2, height / 2)
                        return
                    }

                    let minX = Number(points[0].x)
                    let maxX = Number(points[0].x)
                    let minY = Number(points[0].y)
                    let maxY = Number(points[0].y)

                    for (let i = 0; i < points.length; ++i) {
                        const px = Number(points[i].x)
                        const py = Number(points[i].y)
                        minX = Math.min(minX, px)
                        maxX = Math.max(maxX, px)
                        minY = Math.min(minY, py)
                        maxY = Math.max(maxY, py)
                    }

                    for (let i = 0; i < segments.length; ++i) {
                        const xStart = Number(segments[i].xStart)
                        const xEnd = Number(segments[i].xEnd)
                        const slope = Number(segments[i].slopeValue)
                        const intercept = Number(segments[i].interceptValue)
                        const y1 = slope * xStart + intercept
                        const y2 = slope * xEnd + intercept
                        minX = Math.min(minX, xStart)
                        maxX = Math.max(maxX, xEnd)
                        minY = Math.min(minY, y1, y2)
                        maxY = Math.max(maxY, y1, y2)
                    }

                    if (Math.abs(maxX - minX) < 1e-9)
                        maxX = minX + 1
                    if (Math.abs(maxY - minY) < 1e-9)
                        maxY = minY + 1

                    const padY = (maxY - minY) * 0.08
                    minY -= padY
                    maxY += padY

                    function mapX(value) {
                        return left + ((value - minX) / (maxX - minX)) * drawWidth
                    }

                    function mapY(value) {
                        return top + drawHeight - ((value - minY) / (maxY - minY)) * drawHeight
                    }

                    ctx.strokeStyle = panel.plotGridColor
                    ctx.lineWidth = 1

                    for (let i = 0; i <= 4; ++i) {
                        const y = top + (drawHeight / 4) * i
                        ctx.beginPath()
                        ctx.moveTo(left, y)
                        ctx.lineTo(width - right, y)
                        ctx.stroke()
                    }

                    ctx.strokeStyle = panel.plotBorderColor
                    ctx.lineWidth = 1.5
                    ctx.strokeRect(left, top, drawWidth, drawHeight)

                    if (segments.length > 0) {
                        ctx.strokeStyle = panel.plotLineColor
                        ctx.lineWidth = 3

                        for (let i = 0; i < segments.length; ++i) {
                            const xStart = Number(segments[i].xStart)
                            const xEnd = Number(segments[i].xEnd)
                            const slope = Number(segments[i].slopeValue)
                            const intercept = Number(segments[i].interceptValue)
                            const startX = mapX(xStart)
                            const endX = mapX(xEnd)
                            const startY = mapY(slope * xStart + intercept)
                            const endY = mapY(slope * xEnd + intercept)

                            ctx.beginPath()
                            ctx.moveTo(startX, startY)
                            ctx.lineTo(endX, endY)
                            ctx.stroke()
                        }
                    }

                    ctx.fillStyle = panel.plotPointColor
                    for (let i = 0; i < points.length; ++i) {
                        const px = mapX(Number(points[i].x))
                        const py = mapY(Number(points[i].y))
                        ctx.beginPath()
                        ctx.arc(px, py, 4, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }
        }
    }
}
