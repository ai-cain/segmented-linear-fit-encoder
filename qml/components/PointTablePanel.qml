pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: panel
    required property var theme
    required property var controller
    property string title: "Points Table"
    property string subtitle: "X is fixed. Edit Y values row by row before running the analysis."
    property bool xEditable: false
    property bool allowDelete: false
    property string xHeader: "X"
    property string yHeader: "Y"

    radius: 22
    color: theme.panelAlt
    border.width: 1
    border.color: theme.border

    function formatNumber(value) {
        const numericValue = Number(value)
        if (!isFinite(numericValue))
            return ""

        let text = numericValue.toFixed(6)
        text = text.replace(/\.?0+$/, "")
        return text
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Label {
            text: panel.title
            color: theme.textPrimary
            font.pixelSize: 22
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: theme.textSecondary
            text: panel.subtitle
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 14
            color: theme.field
            border.width: 1
            border.color: theme.fieldBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Label {
                    text: "#"
                    color: theme.textMuted
                    font.bold: true
                    Layout.preferredWidth: 48
                }

                Label {
                    text: panel.xHeader
                    color: theme.textSecondary
                    font.bold: true
                    Layout.preferredWidth: 180
                }

                Label {
                    text: panel.yHeader
                    color: theme.textSecondary
                    font.bold: true
                    Layout.fillWidth: true
                }

                Label {
                    visible: panel.allowDelete
                    text: "Action"
                    color: theme.textSecondary
                    font.bold: true
                    Layout.preferredWidth: panel.allowDelete ? 92 : 0
                }
            }
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
                model: controller.pointModel
                ScrollBar.vertical: ScrollBar { }

                delegate: Rectangle {
                    id: rowCard
                    required property int index
                    required property real xValue
                    required property var yValue
                    required property bool validY

                    readonly property string xText: panel.formatNumber(xValue)
                    readonly property string yText: validY ? panel.formatNumber(yValue) : ""

                    width: ListView.view ? ListView.view.width : 0
                    implicitHeight: 58
                    radius: 14
                    color: rowCard.index % 2 === 0 ? "#0d1728" : "#101b2f"
                    border.width: 1
                    border.color: rowCard.validY ? theme.border : theme.accentSoft

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.fillHeight: true
                            radius: 10
                            color: "#13253f"

                            Label {
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: String(rowCard.index + 1)
                                color: theme.textPrimary
                                font.bold: true
                            }
                        }

                        Rectangle {
                            visible: !panel.xEditable
                            Layout.preferredWidth: 180
                            Layout.fillHeight: true
                            radius: 10
                            color: theme.panel
                            border.width: 1
                            border.color: theme.fieldBorder

                            Label {
                                anchors.fill: parent
                                leftPadding: 12
                                rightPadding: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                text: rowCard.xText
                                color: theme.textPrimary
                            }
                        }

                        TextField {
                            id: xField
                            visible: panel.xEditable
                            Layout.preferredWidth: 180
                            Layout.fillHeight: true
                            property int rowIndex: rowCard.index
                            text: rowCard.xText
                            placeholderText: "Enter X"
                            color: theme.textPrimary
                            selectByMouse: true
                            onEditingFinished: controller.updatePointX(rowIndex, text)

                            background: Rectangle {
                                radius: 10
                                color: theme.panel
                                border.width: 1
                                border.color: theme.fieldBorder
                            }
                        }

                        TextField {
                            id: yField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            property int rowIndex: rowCard.index
                            property bool rowValid: rowCard.validY
                            text: rowCard.yText
                            placeholderText: "Enter Y"
                            color: theme.textPrimary
                            selectByMouse: true
                            onEditingFinished: controller.updatePointY(rowIndex, text)

                            background: Rectangle {
                                radius: 10
                                color: theme.panel
                                border.width: 1
                                border.color: yField.rowValid ? theme.fieldBorder : theme.accentSoft
                            }
                        }

                        Button {
                            visible: panel.allowDelete
                            Layout.preferredWidth: panel.allowDelete ? 92 : 0
                            Layout.fillHeight: true
                            text: "Delete"
                            onClicked: panel.controller.removePoint(rowCard.index)

                            contentItem: Label {
                                text: parent.text
                                color: "#ffd5d5"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                                font.bold: true
                            }

                            background: Rectangle {
                                radius: 10
                                color: parent.down ? "#48212a" : "#2a1520"
                                border.width: 1
                                border.color: "#7f1d1d"
                            }
                        }
                    }
                }
            }
        }
    }
}
