import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.0
import org.kde.kirigami as Kirigami

Item {
    id: configRoot
    implicitWidth: 400
    implicitHeight: 400

    property alias cfg_feedUrls: hiddenField.text
    property string cfg_feedUrlsDefault: ""
    property int cfg_refreshInterval: 300
    property int cfg_refreshIntervalDefault: 300
    property int cfg_maxItems: 20
    property int cfg_maxItemsDefault: 20
    property int cfg_itemSpacing: 4
    property int cfg_itemSpacingDefault: 4
    property int cfg_padding: 8
    property int cfg_paddingDefault: 8
    property int cfg_transparency: 100
    property int cfg_transparencyDefault: 100
    property string cfg_placeholderImage: ""
    property string cfg_placeholderImageDefault: ""
    property string title: i18n("Feeds")

    QQC2.TextField {
        id: hiddenField
        visible: false
    }

    ListModel {
        id: feedModel
    }

    Component.onCompleted: {
        loadFeeds()
    }

    function loadFeeds() {
        feedModel.clear()
        var urls = plasmoid.configuration.feedUrls || ""
        hiddenField.text = urls
        if (urls && typeof urls === 'string') {
            var list = urls.split('\n')
            for (var i = 0; i < list.length; i++) {
                var url = list[i].trim()
                if (url && url.length > 0) {
                    feedModel.append({ feedUrl: url })
                }
            }
        }
    }

    function saveFeeds() {
        var urls = []
        for (var i = 0; i < feedModel.count; i++) {
            urls.push(feedModel.get(i).feedUrl)
        }
        hiddenField.text = urls.join('\n')
        plasmoid.configuration.feedUrls = hiddenField.text
    }

    function moveUp() {
        var idx = feedList.currentIndex
        if (idx > 0) {
            var item = feedModel.get(idx)
            var url = item.feedUrl
            feedModel.remove(idx)
            feedModel.insert(idx - 1, { feedUrl: url })
            feedList.currentIndex = idx - 1
            saveFeeds()
        }
    }

    function moveDown() {
        var idx = feedList.currentIndex
        if (idx >= 0 && idx < feedModel.count - 1) {
            var item = feedModel.get(idx)
            var url = item.feedUrl
            feedModel.remove(idx)
            feedModel.insert(idx + 1, { feedUrl: url })
            feedList.currentIndex = idx + 1
            saveFeeds()
        }
    }

    readonly property color selectedColor: Kirigami.Theme.highlightColor !== undefined ? Kirigami.Theme.highlightColor : "#3498db"
    readonly property color alternateRowColor: Kirigami.Theme.alternateBackgroundColor !== undefined ? Kirigami.Theme.alternateBackgroundColor : "#e8e8e8"
    readonly property color backgroundColor: Kirigami.Theme.backgroundColor !== undefined ? Kirigami.Theme.backgroundColor : "#ffffff"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20

        QQC2.Label {
            text: "RSS Feeds"
            font.bold: true
            font.pixelSize: 14
            color: Kirigami.Theme.textColor
        }

        RowLayout {
            QQC2.Button {
                text: "Add"
                icon.name: "list-add"
                onClicked: {
                    feedModel.append({ feedUrl: "" })
                    saveFeeds()
                    feedList.currentIndex = feedModel.count - 1
                }
            }
            QQC2.Button {
                text: "Remove"
                icon.name: "list-remove"
                enabled: feedList.currentIndex >= 0 && feedList.currentIndex < feedModel.count
                onClicked: {
                    if (feedList.currentIndex >= 0) {
                        feedModel.remove(feedList.currentIndex)
                        saveFeeds()
                    }
                }
            }
            QQC2.Button {
                text: "Up"
                icon.name: "arrow-up"
                enabled: feedModel.count > 1 && feedList.currentIndex > 0
                onClicked: {
                    if (feedList.currentIndex > 0) {
                        var idx = feedList.currentIndex
                        var item = feedModel.get(idx)
                        var url = item.feedUrl
                        feedModel.remove(idx)
                        feedModel.insert(idx - 1, { feedUrl: url })
                        feedList.currentIndex = idx - 1
                        saveFeeds()
                    }
                }
            }
            QQC2.Button {
                text: "Down"
                icon.name: "arrow-down"
                enabled: feedModel.count > 1 && feedList.currentIndex >= 0 && feedList.currentIndex < feedModel.count - 1
                onClicked: {
                    if (feedList.currentIndex >= 0 && feedList.currentIndex < feedModel.count - 1) {
                        var idx = feedList.currentIndex
                        var item = feedModel.get(idx)
                        var url = item.feedUrl
                        feedModel.remove(idx)
                        feedModel.insert(idx + 1, { feedUrl: url })
                        feedList.currentIndex = idx + 1
                        saveFeeds()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: backgroundColor
            radius: 4
            border.color: Kirigami.Theme.separatorColor !== undefined ? Kirigami.Theme.separatorColor : "#cccccc"
            border.width: 1

            ListView {
                id: feedList
                anchors.fill: parent
                anchors.margins: 4
                model: feedModel
                currentIndex: -1
                clip: true

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    id: verticalScrollBar
                    active: true
                }

                delegate: Rectangle {
                    width: feedList.width
                    height: 36
                    color: ListView.isCurrentItem ? selectedColor : (index % 2 === 0 ? alternateRowColor : backgroundColor)
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4

                        QQC2.RadioButton {
                            checked: feedList.currentIndex === index
                            onClicked: feedList.currentIndex = index
                        }

                        QQC2.TextField {
                            id: urlField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: feedUrl
                            placeholderText: "RSS feed URL"
                            font.pixelSize: 12
                            activeFocusOnPress: true
                            selectByMouse: true
                            onTextChanged: {
                                feedModel.set(index, { feedUrl: text })
                            }
                        }

                        QQC2.ToolButton {
                            id: deleteBtn
                            icon.name: "trash-empty"
                            icon.color: "#d32f2f"
                            onClicked: {
                                feedModel.remove(index)
                                saveFeeds()
                            }
                        }
                    }
                }
            }
        }
    }
}
