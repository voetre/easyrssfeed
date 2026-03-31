import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.0

Item {
    id: configRoot
    implicitWidth: 400
    implicitHeight: 400

    property string cfg_feedUrls: plasmoid.configuration.feedUrls || ""

    ListModel {
        id: feedModel
    }

    Component.onCompleted: {
        loadFeeds()
    }

    function loadFeeds() {
        feedModel.clear()
        var configVal = plasmoid.configuration.feedUrls || ""
        if (configVal && typeof configVal === 'string') {
            var list = configVal.split('\n')
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
            var url = feedModel.get(i).feedUrl
            if (url && url.trim()) {
                urls.push(url)
            }
        }
        plasmoid.configuration.feedUrls = urls.join('\n')
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20

        QQC2.Label {
            text: "RSS Feeds"
            font.bold: true
            font.pixelSize: 14
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

        ListView {
            id: feedList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: feedModel
            currentIndex: -1

            delegate: RowLayout {
                width: feedList.width
                height: 36

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
                        saveFeeds()
                    }
                }

                QQC2.ToolButton {
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
