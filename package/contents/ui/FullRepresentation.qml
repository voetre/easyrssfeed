import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
    id: window
    width: 640
    height: 480
    implicitWidth: 640
    implicitHeight: 480
    Layout.minimumWidth: 500
    Layout.minimumHeight: 350

    property var feedUrls: []
    property string currentFeedUrl: ""
    property int refreshInterval: plasmoid.configuration.refreshInterval ? 1000 * plasmoid.configuration.refreshInterval : 300000
    property int maxItems: plasmoid.configuration.maxItems ? plasmoid.configuration.maxItems : 20
    property string placeholderImage: plasmoid.configuration.placeholderImage ? plasmoid.configuration.placeholderImage : ""
    property int itemSpacing: plasmoid.configuration.itemSpacing ? plasmoid.configuration.itemSpacing : 4
    property int padding: plasmoid.configuration.padding ? plasmoid.configuration.padding : 8
    property int transparency: plasmoid.configuration.transparency !== undefined ? plasmoid.configuration.transparency : 100

    property bool isLoading: true
    property int currentFeedIndex: 0
    property var feedItems: []
    property bool showAllFeeds: true

    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color dateColor: Kirigami.Theme.disabledTextColor

    Component.onCompleted: {
        console.log("FullRepresentation loaded")
        reloadFeeds()
    }

    function getConfigFeeds() {
        var configVal = plasmoid.configuration.feedUrls
        if (Array.isArray(configVal)) {
            return configVal.join('\n')
        } else if (typeof configVal === 'string') {
            return configVal
        }
        return ""
    }

    function updateTabModel() {
        tabModel.clear()
        if (showAllFeeds && feedUrls.length > 1) {
            tabModel.append({ url: "", name: i18n("All Feeds"), isAllFeeds: true })
        }
        for (var i = 0; i < feedUrls.length; i++) {
            tabModel.append({ 
                url: feedUrls[i], 
                name: getSiteName(feedUrls[i]), 
                isAllFeeds: false,
                iconUrl: getFaviconUrl(feedUrls[i])
            })
        }
        feedTabs.currentIndex = -1
        feedTabs.currentIndex = 0
    }

    function reloadFeeds() {
        var urls = getConfigFeeds()
        
        var newUrls = []
        if (urls) {
            var list = urls.split('\n')
            for (var i = 0; i < list.length; i++) {
                var url = list[i].trim()
                if (url && url.length > 0) {
                    newUrls.push(url)
                }
            }
        }
        
        var urlsChanged = JSON.stringify(feedUrls) !== JSON.stringify(newUrls)
        
        if (urlsChanged) {
            console.log("Feeds changed:", newUrls)
            
            feedUrls = newUrls
            feedItems = []
            
            if (feedUrls.length > 0) {
                currentFeedIndex = (showAllFeeds && feedUrls.length > 1) ? 1 : 0
                currentFeedUrl = feedUrls[0]
            } else {
                currentFeedIndex = 0
                currentFeedUrl = ""
            }
            
            updateTabModel()
            
            if (currentFeedUrl) {
                loadFeed(currentFeedUrl)
            }
        }
    }

    function getSiteName(url) {
        try {
            var match = url.match(/^https?:\/\/([^\/]+)/);
            if (!match || !match[1]) return url;
            
            var domain = match[1].replace(/^www\./, '');
            var parts = domain.split('.');
            
            var compoundTlds = ['co', 'com', 'org', 'net', 'gov', 'edu', 'ac', 'io', 'dev'];
            
            if (parts.length >= 3 && compoundTlds.indexOf(parts[parts.length - 2]) !== -1) {
                return parts[parts.length - 3].charAt(0).toUpperCase() + parts[parts.length - 3].slice(1);
            } else if (parts.length >= 2) {
                return parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
            }
            return parts[0];
        } catch(e) {}
        return url;
    }

    function getSiteDomain(url) {
        try {
            var match = url.match(/^https?:\/\/([^\/]+)/);
            if (!match || !match[1]) return url;
            
            var domain = match[1].replace(/^www\./, '');
            var parts = domain.split('.');
            
            var compoundTlds = ['co', 'com', 'org', 'net', 'gov', 'edu', 'ac', 'io', 'dev'];
            
            if (parts.length >= 3 && compoundTlds.indexOf(parts[parts.length - 2]) !== -1) {
                return parts.slice(-3).join('.');
            } else if (parts.length >= 2) {
                return parts.slice(-2).join('.');
            }
            return domain;
        } catch(e) {}
        return url;
    }

    function getFaviconUrl(url) {
        return "https://www.google.com/s2/favicons?domain=" + getSiteDomain(url) + "&sz=32";
    }

    function loadFeed(url) {
        isLoading = true;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoading = false;
                if (xhr.status === 200) {
                    parseXml(xhr.responseText);
                } else {
                    console.log("Error loading feed:", xhr.status, xhr.statusText);
                    feedItems = [];
                }
            }
        };
        xhr.onerror = function(e) {
            console.log("Network error:", e);
            isLoading = false;
            feedItems = [];
        };
        xhr.send();
    }

    function loadAllFeeds() {
        if (feedUrls.length === 0) {
            feedItems = [];
            return;
        }
        
        isLoading = true;
        var allItems = [];
        var loadedCount = 0;
        var totalFeeds = feedUrls.length;
        
        function checkComplete() {
            loadedCount++;
            if (loadedCount >= totalFeeds) {
                isLoading = false;
                allItems.sort(function(a, b) {
                    var dateA = new Date(a.pubDate);
                    var dateB = new Date(b.pubDate);
                    return dateB - dateA;
                });
                feedItems = allItems.slice(0, maxItems);
                console.log("Loaded", feedItems.length, "items from all feeds");
            }
        }
        
        for (var i = 0; i < feedUrls.length; i++) {
            (function(url) {
                var xhr = new XMLHttpRequest();
                xhr.open("GET", url);
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            var items = getAllItems(xhr.responseText);
                            for (var j = 0; j < Math.min(items.length, Math.ceil(maxItems / totalFeeds) + 2); j++) {
                                var itemXml = items[j];
                                var title = getTagContent(itemXml, "title");
                                var link = getLinkFromItem(itemXml);
                                var description = getTagContent(itemXml, "description") || getTagContent(itemXml, "summary");
                                var pubDate = getTagContent(itemXml, "pubDate") || getTagContent(itemXml, "published") || getTagContent(itemXml, "updated") || getTagContent(itemXml, "dc:date");
                                var author = getTagContent(itemXml, "author") || getTagContent(itemXml, "dc:creator") || getTagContent(itemXml, "name");
                                var content = getTagContent(itemXml, "content:encoded") || getTagContent(itemXml, "content");
                                
                                allItems.push({
                                    title: title || "Untitled",
                                    link: link || "",
                                    description: description || "",
                                    pubDate: pubDate || "",
                                    author: author || "",
                                    content: content || description || "",
                                    sourceUrl: url
                                });
                            }
                        }
                        checkComplete();
                    }
                };
                xhr.onerror = function() {
                    checkComplete();
                };
                xhr.send();
            })(feedUrls[i]);
        }
    }

    function getTagContent(xml, tagName) {
        var patterns = [
            new RegExp('<' + tagName + '[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/' + tagName + '>', 'i'),
            new RegExp('<' + tagName + '[^>]*>([\\s\\S]*?)<\\/' + tagName + '>', 'i')
        ];
        
        for (var i = 0; i < patterns.length; i++) {
            var match = xml.match(patterns[i]);
            if (match && match[1]) {
                return match[1].trim();
            }
        }
        return "";
    }

    function getLinkFromItem(itemXml) {
        var linkPatterns = [
            /<link[^>]*href=["']([^"']+)["'][^>]*>/i,
            /<link[^>]*><!\[CDATA\[([^\]]+)\]\]><\/link>/i,
            /<link[^>]*>([^<]+)<\/link>/i,
            /<link>([^<]+)<\/link>/i
        ];
        
        for (var i = 0; i < linkPatterns.length; i++) {
            var match = itemXml.match(linkPatterns[i]);
            if (match && match[1]) {
                return match[1].trim();
            }
        }
        return "";
    }

    function getAllItems(xml) {
        var items = [];
        var itemPattern = /<item[\s\S]*?<\/item>/gi;
        var entryPattern = /<entry[\s\S]*?<\/entry>/gi;
        
        var matches = xml.match(itemPattern);
        if (!matches) {
            matches = xml.match(entryPattern);
        }
        
        if (matches) {
            for (var i = 0; i < Math.min(matches.length, maxItems); i++) {
                items.push(matches[i]);
            }
        }
        return items;
    }

    function parseXml(xmlText) {
        var items = getAllItems(xmlText);
        var parsedItems = [];
        
        for (var i = 0; i < items.length; i++) {
            var itemXml = items[i];
            
            var title = getTagContent(itemXml, "title");
            var link = getLinkFromItem(itemXml);
            var description = getTagContent(itemXml, "description") || getTagContent(itemXml, "summary");
            var pubDate = getTagContent(itemXml, "pubDate") || getTagContent(itemXml, "published") || getTagContent(itemXml, "updated") || getTagContent(itemXml, "dc:date");
            var author = getTagContent(itemXml, "author") || getTagContent(itemXml, "dc:creator") || getTagContent(itemXml, "name");
            var content = getTagContent(itemXml, "content:encoded") || getTagContent(itemXml, "content");
            
            parsedItems.push({
                title: title || "Untitled",
                link: link || "",
                description: description || "",
                pubDate: pubDate || "",
                author: author || "",
                content: content || description || ""
            });
        }
        
        feedItems = parsedItems;
        console.log("Loaded", parsedItems.length, "items");
    }

    function extractImageFromDescription(desc) {
        if (!desc) return "";
        var imgRegex = /<img[^>]+src=["']([^"']+)["']/i;
        var match = desc.match(imgRegex);
        if (match && match[1]) return match[1];
        
        var mediaRegex = /<media:content[^>]+url=["']([^"']+)["']/i;
        match = desc.match(mediaRegex);
        if (match && match[1]) return match[1];
        
        return "";
    }

    function decodeHtmlEntities(str) {
        if (!str) return "";
        var result = str;
        result = result.replace(/&#(\d+);/g, function(m, dec) { return String.fromCharCode(dec); });
        result = result.replace(/&#x([0-9a-fA-F]+);/g, function(m, hex) { return String.fromCharCode(parseInt(hex, 16)); });
        result = result.replace(/&amp;/g, "&");
        result = result.replace(/&lt;/g, "<");
        result = result.replace(/&gt;/g, ">");
        result = result.replace(/&quot;/g, '"');
        result = result.replace(/&apos;/g, "'");
        result = result.replace(/&nbsp;/g, " ");
        return result;
    }

    function stripHtml(str) {
        if (!str) return "";
        var decoded = decodeHtmlEntities(str);
        return decoded.replace(/<[^>]*>/g, '').trim();
    }

    function formatDate(dateStr) {
        if (!dateStr) return "";
        var d = new Date(dateStr);
        if (isNaN(d.getTime())) {
            return dateStr;
        }
        var now = new Date();
        var diff = now - d;
        var seconds = Math.floor(diff / 1000);
        var minutes = Math.floor(seconds / 60);
        var hours = Math.floor(minutes / 60);
        var days = Math.floor(hours / 24);

        if (days > 7) {
            return d.toLocaleDateString();
        } else if (days > 0) {
            return days === 1 ? i18n("Yesterday") : i18np("1 day ago", "%1 days ago", days);
        } else if (hours > 0) {
            return i18np("1 hour ago", "%1 hours ago", hours);
        } else if (minutes > 0) {
            return i18np("1 minute ago", "%1 minutes ago", minutes);
        } else {
            return i18n("Just now");
        }
    }

    Component {
        id: feedDelegate
        Rectangle {
            id: delegateRoot
            height: feedItemLayout.height + itemSpacing
            width: parent ? parent.width : window.width
            color: Kirigami.Theme.alternateBackgroundColor !== undefined ? Kirigami.Theme.alternateBackgroundColor : "#e8e8e8"
            radius: 4

            ColumnLayout {
                id: feedItemLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: padding
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Image {
                        id: itemImage
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60
                        Layout.minimumWidth: 60
                        Layout.minimumHeight: 60
                        fillMode: Image.PreserveAspectCrop
                        source: {
                            var img = extractImageFromDescription(modelData.content || modelData.description);
                            if (img) return img;
                            if (placeholderImage !== "") return placeholderImage;
                            return "";
                        }
                        sourceSize.width: 60
                        sourceSize.height: 60
                        Rectangle {
                            anchors.fill: parent
                            color: Kirigami.Theme.backgroundColor !== undefined ? Kirigami.Theme.backgroundColor : "#f0f0f0"
                            visible: parent.status !== Image.Ready || parent.source === ""
                            radius: 4
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                source: "rss"
                                width: 24
                                height: 24
                                visible: parent.visible
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: decodeHtmlEntities(modelData.title) || "Untitled"
                            font.bold: true
                            font.pixelSize: 13
                            color: textColor
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: formatDate(modelData.pubDate)
                            font.pixelSize: 10
                            color: dateColor
                        }
                    }
                }

                Text {
                    text: {
                        var text = stripHtml(modelData.description || modelData.content || "");
                        return text.substring(0, 200) + (text.length > 200 ? "..." : "");
                    }
                    font.pixelSize: 11
                    color: textColor
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: (modelData.description || modelData.content || "") !== ""
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 4
                    color: Kirigami.Theme.separatorColor !== undefined ? Kirigami.Theme.separatorColor : "#cccccc"
                    visible: index < (feedItems.length - 1)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modelData.link) {
                        Qt.openUrlExternally(modelData.link);
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor !== undefined ? Kirigami.Theme.backgroundColor : "#ffffff"
        opacity: transparency / 100
        radius: 8
        z: -2
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: padding
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 160
            Layout.minimumWidth: 160
            color: Kirigami.Theme.backgroundColor !== undefined ? Kirigami.Theme.backgroundColor : "#f5f5f5"
            radius: 4
            visible: feedUrls.length > 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Label {
                    text: i18n("Feeds")
                    font.bold: true
                    font.pixelSize: 12
                    color: dateColor
                }

                ListView {
                    id: feedTabs
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    model: ListModel {
                        id: tabModel
                    }

                    delegate: Rectangle {
                        width: feedTabs.width
                        height: 44
                        radius: 4
                        color: index === currentFeedIndex ? Kirigami.Theme.highlightColor : Kirigami.Theme.alternateBackgroundColor
                        opacity: index === currentFeedIndex ? 1 : 0.8

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    source: isAllFeeds ? "feed" : (iconUrl || "rss")
                                }
                            }

                            Text {
                                text: isAllFeeds ? i18n("All Feeds") : (name || "Feed")
                                font.pixelSize: 12
                                color: index === currentFeedIndex ? Kirigami.Theme.highlightedTextColor : textColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.maximumWidth: 100
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                currentFeedIndex = index;
                                if (isAllFeeds) {
                                    currentFeedUrl = "";
                                    feedItems = [];
                                    loadAllFeeds();
                                } else if (url) {
                                    currentFeedUrl = url;
                                    feedItems = [];
                                    loadFeed(currentFeedUrl);
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Kirigami.Theme.backgroundColor !== undefined ? Kirigami.Theme.backgroundColor : "#ffffff"
            radius: 4

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: Kirigami.Theme.backgroundColor !== undefined ? Kirigami.Theme.backgroundColor : "#ffffff"
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        ToolButton {
                            id: configButton
                            icon.name: "configure"
                            ToolTip.text: i18n("Settings")
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var action = plasmoid.internalAction("configure");
                                    if (action) action.trigger();
                                }
                            }
                        }

                        ToolButton {
                            icon.name: "view-refresh"
                            onClicked: loadFeed(currentFeedUrl)
                            ToolTip.text: i18n("Refresh")
                        }

                        ToolButton {
                            icon.name: "window-close"
                            onClicked: plasmoid.expanded = false
                            ToolTip.text: i18n("Close")
                        }
                    }
                }

                ListView {
                    id: feedList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: padding / 2
                    clip: true
                    spacing: itemSpacing
                    model: feedItems
                    delegate: feedDelegate
                    verticalLayoutDirection: ListView.TopToBottom
                    boundsBehavior: Flickable.StopAtBounds
                    maximumFlickVelocity: 2000

                    Label {
                        anchors.centerIn: parent
                        text: feedItems.length === 0 && !isLoading ? i18n("No items found") : ""
                        color: dateColor
                        font.pixelSize: 12
                        visible: feedItems.length === 0 && !isLoading
                    }
                }
            }
        }
    }

    Item {
        id: busyIndicator
        anchors.centerIn: parent
        z: 10
        visible: isLoading

        BusyIndicator {
            anchors.centerIn: parent
            running: isLoading
        }

        Text {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18n("Loading...")
            font.pixelSize: 12
            color: Kirigami.Theme.disabledTextColor
            visible: isLoading
        }
    }

    Timer {
        id: refreshTimer
        interval: refreshInterval
        running: currentFeedUrl !== "" && refreshInterval > 0
        repeat: true
        onTriggered: loadFeed(currentFeedUrl)
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Configure")
            icon.name: "configure"
            onTriggered: {
                var action = plasmoid.internalAction("configure");
                if (action) action.trigger();
            }
        },
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            onTriggered: loadFeed(currentFeedUrl)
        }
    ]

    Timer {
        id: configCheckTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: reloadFeeds()
    }
}
