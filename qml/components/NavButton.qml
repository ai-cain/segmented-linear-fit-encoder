pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: control
    required property var theme
    property string subtitle: ""
    property bool selected: false

    implicitHeight: Math.max(74, navContent.implicitHeight + 20)
    padding: 0

    contentItem: RowLayout {
        id: navContent
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        Rectangle {
            width: 4
            Layout.fillHeight: true
            radius: 2
            color: control.selected ? control.theme.accent : "transparent"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: control.text
                color: control.selected ? control.theme.textPrimary : control.theme.textSecondary
                font.pixelSize: 15
                font.bold: true
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: control.subtitle
                color: control.theme.textMuted
                font.pixelSize: 12
            }
        }
    }

    background: Rectangle {
        radius: 16
        color: control.selected
               ? Qt.rgba(control.theme.accent.r, control.theme.accent.g, control.theme.accent.b, 0.16)
               : (control.down ? "#15243a" : "transparent")
        border.width: 1
        border.color: control.selected ? control.theme.accentSoft : "transparent"
    }
}
