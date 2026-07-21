pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    required property string screenName

    readonly property bool hasCustomWallpaper: SettingsData.lockScreenWallpaperPath !== ""

    function encodeFileUrl(path) {
        if (!path)
            return "";
        return "file://" + path.split('/').map(s => encodeURIComponent(s)).join('/');
    }

    Rectangle {
        anchors.fill: parent
        color: SettingsData.effectiveWallpaperBackgroundColor
    }

    Loader {
        anchors.fill: parent
        active: {
            if (root.hasCustomWallpaper)
                return false;
            var currentWallpaper = SessionData.getMonitorWallpaper(screenName);
            return !currentWallpaper || (currentWallpaper && currentWallpaper.startsWith("#"));
        }
        asynchronous: true

        sourceComponent: DankBackdrop {
            screenName: root.screenName
        }
    }

    Loader {
        id: wallpaperBackground
        anchors.fill: parent

        readonly property string wallpaperSource: {
            if (root.hasCustomWallpaper)
                return root.encodeFileUrl(SettingsData.lockScreenWallpaperPath);
            var w = SessionData.getMonitorWallpaper(screenName);
            return (w && !w.startsWith("#")) ? encodeFileUrl(w) : "";
        }
        readonly property string fillModeName: {
            if (SettingsData.lockScreenWallpaperFillMode !== "")
                return SettingsData.lockScreenWallpaperFillMode;
            return root.hasCustomWallpaper ? "Fill" : SessionData.getMonitorWallpaperFillMode(root.screenName);
        }

        active: wallpaperSource !== ""
        asynchronous: false

        sourceComponent: fillModeName === "Scrolling" ? scrollWallpaperComp : plainWallpaperComp

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.8
            blurMax: 32
            blurMultiplier: 1
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.standardEasing
            }
        }
    }

    Component {
        id: plainWallpaperComp
        Image {
            source: wallpaperBackground.wallpaperSource
            fillMode: Theme.getFillMode(wallpaperBackground.fillModeName)
            smooth: true
            cache: true
            asynchronous: false
        }
    }

    Component {
        id: scrollWallpaperComp
        Item {
            Image {
                id: scrollSource
                anchors.fill: parent
                visible: false
                source: wallpaperBackground.wallpaperSource
                asynchronous: false
                cache: true
            }

            ShaderEffectSource {
                id: scrollSrc
                sourceItem: scrollSource
                hideSource: true
                live: false
            }

            ShaderEffect {
                anchors.fill: parent

                readonly property var scrollPos: SessionData.getMonitorScrollPosition(screenName)

                property variant source1: scrollSrc
                property variant source2: scrollSrc
                property real progress: 0.0
                property real fillMode: Theme.getShaderFillMode(wallpaperBackground.fillModeName)
                property real scrollX: scrollPos.scrollX
                property real scrollY: scrollPos.scrollY
                property real imageWidth1: scrollSource.implicitWidth > 0 ? scrollSource.implicitWidth : 1
                property real imageHeight1: scrollSource.implicitHeight > 0 ? scrollSource.implicitHeight : 1
                property real imageWidth2: imageWidth1
                property real imageHeight2: imageHeight1
                property real screenWidth: width > 0 ? width : 1
                property real screenHeight: height > 0 ? height : 1
                property vector4d fillColor: Qt.vector4d(0, 0, 0, 1)

                fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_fade.frag.qsb")
            }
        }
    }
}
