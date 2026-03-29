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

    radius: 22
    color: theme.panelAlt
    border.width: 1
    border.color: theme.border

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
                    text: "X"
                    color: theme.textSecondary
                    font.bold: true
                    Layout.preferredWidth: 180
                }

                Label {
                    text: "Y"
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
                    id: pointRow
                    required property int index
                    required property string displayX
                    required property string displayY
                    required property bool validY

                    width: ListView.view ? ListView.view.width : 0
                    implicitHeight: 58
                    radius: 14
                    color: pointRow.index % 2 === 0 ? "#0d1728" : "#101b2f"
                    border.width: 1
                    border.color: pointRow.validY ? theme.border : theme.accentSoft

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
                                anchors.centerIn: parent
                                text: String(pointRow.index + 1)
                                color: theme.textPrimary
                                font.bold: true
                            }
                        }

                        Loader {
                            Layout.preferredWidth: 180
                            Layout.fillHeight: true
                            active: true
                            sourceComponent: panel.xEditable ? editableXComponent : fixedXComponent
                        }

                        TextField {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: pointRow.displayY
                            placeholderText: "Enter Y"
                            color: theme.textPrimary
                            selectByMouse: true
                            onEditingFinished: controller.updatePointY(pointRow.index, text)

                            background: Rectangle {
                                radius: 10
                                color: theme.panel
                                border.width: 1
                                border.color: pointRow.validY ? theme.fieldBorder : theme.accentSoft
                            }
                        }

                        Loader {
                            Layout.preferredWidth: panel.allowDelete ? 92 : 0
                            Layout.fillHeight: true
                            active: panel.allowDelete
                            sourceComponent: deleteComponent
                        }
                    }
                }
            }
        }
    }

    Component {
        id: fixedXComponent

        Rectangle {
            radius: 10
            color: panel.theme.panel
            border.width: 1
            border.color: panel.theme.fieldBorder

            Label {
                anchors.centerIn: parent
                text: pointRow.displayX
                color: panel.theme.textPrimary
            }
        }
    }

    Component {
        id: editableXComponent

        TextField {
            text: pointRow.displayX
            placeholderText: "Enter X"
            color: panel.theme.textPrimary
            selectByMouse: true
            onEditingFinished: panel.controller.updatePointX(pointRow.index, text)

            background: Rectangle {
                radius: 10
                color: panel.theme.panel
                border.width: 1
                border.color: panel.theme.fieldBorder
            }
        }
    }

    Component {
        id: deleteComponent

        Button {
            text: "Delete"
            onClicked: panel.controller.removePoint(pointRow.index)

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
