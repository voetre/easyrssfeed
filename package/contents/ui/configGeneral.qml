import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.0
import org.kde.kirigami as Kirigami

Item {
    id: configRoot
    implicitWidth: 400
    implicitHeight: 400

    property string cfg_feedUrls: ""
    property string cfg_feedUrlsDefault: ""
    property alias cfg_refreshInterval: refreshInterval.value
    property int cfg_refreshIntervalDefault: 300
    property alias cfg_maxItems: maxItems.value
    property int cfg_maxItemsDefault: 20
    property alias cfg_itemSpacing: itemSpacing.value
    property int cfg_itemSpacingDefault: 4
    property alias cfg_padding: padding.value
    property int cfg_paddingDefault: 8
    property alias cfg_transparency: transparency.value
    property int cfg_transparencyDefault: 100
    property alias cfg_placeholderImage: placeholderImage.text
    property string cfg_placeholderImageDefault: ""
    property string title: i18n("General")

    readonly property color textColor: Kirigami.Theme.textColor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20

        QQC2.Label {
            text: "General Settings"
            font.bold: true
            font.pixelSize: 14
            color: textColor
        }

        RowLayout {
            QQC2.Label { 
                text: "Refresh interval (seconds):"
                color: textColor
            }
            QQC2.SpinBox {
                id: refreshInterval
                from: 0
                to: 3600
                stepSize: 30
            }
        }

        RowLayout {
            QQC2.Label { 
                text: "Max items per feed:"
                color: textColor
            }
            QQC2.SpinBox {
                id: maxItems
                from: 1
                to: 100
            }
        }

        RowLayout {
            QQC2.Label { 
                text: "Item spacing (px):"
                color: textColor
            }
            QQC2.SpinBox {
                id: itemSpacing
                from: 0
                to: 20
            }
        }

        RowLayout {
            QQC2.Label { 
                text: "Padding (px):"
                color: textColor
            }
            QQC2.SpinBox {
                id: padding
                from: 0
                to: 30
            }
        }

        RowLayout {
            QQC2.Label { 
                text: "Transparency (%):"
                color: textColor
            }
            QQC2.SpinBox {
                id: transparency
                from: 10
                to: 100
                stepSize: 10
            }
        }

        RowLayout {
            QQC2.Label { 
                text: "Placeholder image URL:"
                color: textColor
            }
            QQC2.TextField {
                id: placeholderImage
                Layout.fillWidth: true
                placeholderText: "Optional image URL"
            }
        }

        Item { Layout.fillHeight: true }
    }
}
