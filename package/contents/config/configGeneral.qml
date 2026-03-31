import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.0

Item {
    id: configRoot
    implicitWidth: 400
    implicitHeight: 300

    property alias cfg_refreshInterval: refreshInterval.value
    property alias cfg_maxItems: maxItems.value

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20

        QQC2.Label {
            text: "General Settings"
            font.bold: true
            font.pixelSize: 14
        }

        RowLayout {
            QQC2.Label { text: "Refresh interval:" }
            QQC2.SpinBox {
                id: refreshInterval
                from: 0
                to: 3600
                stepSize: 30
            }
        }

        RowLayout {
            QQC2.Label { text: "Max items:" }
            QQC2.SpinBox {
                id: maxItems
                from: 1
                to: 100
            }
        }

        Item { Layout.fillHeight: true }
    }
}
