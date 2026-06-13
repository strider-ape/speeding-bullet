import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // ── Always show compact (panel) view ─────────────────────────────────
    preferredRepresentation: compactRepresentation

    // ── Inter font ────────────────────────────────────────────────────────
    FontLoader {
        id: interFont
        source: Qt.resolvedUrl("../fonts/Inter-Regular.ttf")
    }

    // ── State ─────────────────────────────────────────────────────────────
    property real downloadSpeed: 0   // bytes/s
    property real uploadSpeed:   0   // bytes/s
    property var  prevRx:        ({})
    property var  prevTx:        ({})
    property real prevTime:      0   // ms

    // ── Interface prefixes to skip ────────────────────────────────────────
    readonly property var skipPrefixes: [
        "lo", "tun", "virbr", "docker", "veth", "br-",
        "vmnet", "vboxnet", "dummy", "bond"
    ]

    function shouldSkip(name) {
        for (var i = 0; i < skipPrefixes.length; i++) {
            if (name.indexOf(skipPrefixes[i]) === 0) return true
        }
        return false
    }

    // ── Speed formatter ───────────────────────────────────────────────────
    function fmt(bps) {
        if      (bps >= 1073741824) return (bps / 1073741824).toFixed(2) + " GB/s"
        else if (bps >= 1048576)    return (bps / 1048576   ).toFixed(2) + " MB/s"
        else if (bps >= 1024)       return (bps / 1024      ).toFixed(1) + " KB/s"
        else                        return bps.toFixed(0)               + " B/s"
    }

    // ── Executable DataSource — runs shell commands, returns stdout ────────
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            root.parseNetDev(data["stdout"] || "")
        }
    }

    // ── Parse /proc/net/dev output ────────────────────────────────────────
    function parseNetDev(text) {
        var now  = Date.now()
        var lines = text.split("\n")
        var curRx = {}
        var curTx = {}

        for (var i = 2; i < lines.length; i++) {
            var line  = lines[i].trim()
            if (!line) continue

            var colon = line.indexOf(":")
            if (colon < 0) continue

            var iface = line.substring(0, colon).trim()
            if (shouldSkip(iface)) continue

            var cols = line.substring(colon + 1).trim().split(/\s+/)
            if (cols.length < 9) continue

            curRx[iface] = parseInt(cols[0], 10) || 0   // rx bytes
            curTx[iface] = parseInt(cols[8], 10) || 0   // tx bytes
        }

        if (root.prevTime > 0) {
            var dt  = (now - root.prevTime) / 1000.0
            var dRx = 0
            var dTx = 0
            for (var k in curRx) {
                dRx += curRx[k] - (root.prevRx[k] || 0)
                dTx += curTx[k] - (root.prevTx[k] || 0)
            }
            root.downloadSpeed = Math.max(0, dRx / dt)
            root.uploadSpeed   = Math.max(0, dTx / dt)
        }

        root.prevRx   = curRx
        root.prevTx   = curTx
        root.prevTime = now
    }

    // ── 1-second polling timer ────────────────────────────────────────────
    Timer {
        interval:         1000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered:      executable.connectSource("cat /proc/net/dev")
    }

    // ══════════════════════════════════════════════════════════════════════
    // Compact representation — shown in the panel
    // ══════════════════════════════════════════════════════════════════════
    compactRepresentation: Item {
        id: panelItem

        implicitWidth:  speedCol.implicitWidth  + Kirigami.Units.smallSpacing * 3
        implicitHeight: speedCol.implicitHeight + Kirigami.Units.smallSpacing

        ColumnLayout {
            id: speedCol
            anchors.centerIn: parent
            spacing: 1

            // ── Download row ──────────────────────────────────────────
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignRight

                Text {
                    text:             "↓"
                    font.family:      interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize:   Math.round(Kirigami.Units.gridUnit * 0.68)
                    font.weight:      Font.Medium
                    color:            Kirigami.Theme.positiveTextColor
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text:             root.fmt(root.downloadSpeed)
                    font.family:      interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize:   Math.round(Kirigami.Units.gridUnit * 0.68)
                    font.weight:      Font.Medium
                    color:            Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignRight
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 4.8
                    verticalAlignment:   Text.AlignVCenter
                }
            }

            // ── Upload row ────────────────────────────────────────────
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignRight

                Text {
                    text:             "↑"
                    font.family:      interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize:   Math.round(Kirigami.Units.gridUnit * 0.68)
                    font.weight:      Font.Medium
                    color:            Kirigami.Theme.neutralTextColor
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    text:             root.fmt(root.uploadSpeed)
                    font.family:      interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize:   Math.round(Kirigami.Units.gridUnit * 0.68)
                    font.weight:      Font.Medium
                    color:            Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignRight
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 4.8
                    verticalAlignment:   Text.AlignVCenter
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Full representation — shown when expanded / on desktop
    // ══════════════════════════════════════════════════════════════════════
    fullRepresentation: Item {
        implicitWidth:  Kirigami.Units.gridUnit * 14
        implicitHeight: Kirigami.Units.gridUnit * 6

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Text {
                Layout.alignment:    Qt.AlignHCenter
                text:                "Network Speed"
                font.family:         interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                font.pixelSize:      Kirigami.Units.gridUnit * 0.85
                font.weight:         Font.SemiBold
                font.letterSpacing:  1.2
                color:               Kirigami.Theme.disabledTextColor
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing
                Text {
                    text:           "↓"
                    font.family:    interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize: Kirigami.Units.gridUnit * 1.4
                    font.weight:    Font.Medium
                    color:          Kirigami.Theme.positiveTextColor
                }
                Text {
                    text:           root.fmt(root.downloadSpeed)
                    font.family:    interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize: Kirigami.Units.gridUnit * 1.4
                    font.weight:    Font.Medium
                    color:          Kirigami.Theme.textColor
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing
                Text {
                    text:           "↑"
                    font.family:    interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize: Kirigami.Units.gridUnit * 1.4
                    font.weight:    Font.Medium
                    color:          Kirigami.Theme.neutralTextColor
                }
                Text {
                    text:           root.fmt(root.uploadSpeed)
                    font.family:    interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize: Kirigami.Units.gridUnit * 1.4
                    font.weight:    Font.Medium
                    color:          Kirigami.Theme.textColor
                }
            }
        }
    }
}
