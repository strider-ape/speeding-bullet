import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    toolTipMainText: "Today's Usage"
    toolTipSubText: "↓ " + root.fmtBytes(root.dailyDownload) + "\n↑ " + root.fmtBytes(root.dailyUpload)

    // ── Inter font ────────────────────────────────────────────────────────
    FontLoader {
        id: interFont
        source: Qt.resolvedUrl("../fonts/Inter-Regular.ttf")
    }

    // ── State ─────────────────────────────────────────────────────────────
    property real downloadSpeed: 0
    property real uploadSpeed:   0
    property var  prevRx:        ({})
    property var  prevTx:        ({})
    property real prevTime:      0
    property real dailyDownload: 0
    property real dailyUpload:   0

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

    function fmt(bps) {
        if      (bps >= 1073741824) return (bps / 1073741824).toFixed(2) + " GB/s"
        else if (bps >= 1048576)    return (bps / 1048576   ).toFixed(2) + " MB/s"
        else if (bps >= 1024)       return (bps / 1024      ).toFixed(1) + " KB/s"
        else                        return bps.toFixed(0)               + " B/s"
    }

    function fmtBytes(bytes) {
        if      (bytes >= 1073741824) return (bytes / 1073741824).toFixed(2) + " GB"
        else if (bytes >= 1048576)    return (bytes / 1048576   ).toFixed(2) + " MB"
        else if (bytes >= 1024)       return (bytes / 1024      ).toFixed(1) + " KB"
        else                          return bytes.toFixed(0)               + " B"
    }

    // ── DataSource ────────────────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            root.parseNetDev(data["stdout"] || "")
        }
    }

    function parseNetDev(text) {
        var now   = Date.now()
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
            var cols  = line.substring(colon + 1).trim().split(/\s+/)
            if (cols.length < 9) continue
            curRx[iface] = parseInt(cols[0], 10) || 0
            curTx[iface] = parseInt(cols[8], 10) || 0
        }

        if (root.prevTime > 0) {
            var dt  = (now - root.prevTime) / 1000.0
            var dRx = 0, dTx = 0
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

    Timer {
        interval:         1000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered:      executable.connectSource("cat /proc/net/dev")
    }

    // ── Daily Usage DataSource (vnstat) ───────────────────────────────────
    Plasma5Support.DataSource {
        id: vnstatExecutable
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            root.parseVnstat(data["stdout"] || "")
        }
    }

    function parseVnstat(jsonText) {
        if (!jsonText.trim()) return;
        try {
            var data = JSON.parse(jsonText)
            var totalRx = 0
            var totalTx = 0
            
            var interfaces = data.interfaces || []
            for (var i = 0; i < interfaces.length; i++) {
                var iface = interfaces[i]
                if (shouldSkip(iface.name)) continue
                
                var traffic = iface.traffic || {}
                var day = traffic.day || []
                if (day.length > 0) {
                    totalRx += day[0].rx || 0
                    totalTx += day[0].tx || 0
                }
            }
            root.dailyDownload = totalRx
            root.dailyUpload   = totalTx
        } catch (e) {
            console.log("Error parsing vnstat JSON:", e)
        }
    }

    Timer {
        interval:         60000 // Refresh every 1 minute
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered:      vnstatExecutable.connectSource("vnstat --json d 1")
    }

    // ══════════════════════════════════════════════════════════════════════
    // Compact representation — panel view
    // ══════════════════════════════════════════════════════════════════════
    compactRepresentation: Item {
        id: panelRoot
        readonly property int fSize: Math.round(Kirigami.Units.gridUnit * 0.68 * (Plasmoid.configuration.fontSizeScale || 1.0))

        // 1. Tell the panel's containment layout exactly how much space to allocate.
        // We use Math.max to provide a safe fallback (≈ 100px) while the custom font loads,
        // preventing the layout engine from ever registering a 0-width state.
        Layout.minimumWidth: Math.max(Kirigami.Units.gridUnit * 5.5, dummyMetrics.advanceWidth + Kirigami.Units.largeSpacing)
        Layout.preferredWidth: Layout.minimumWidth
        
        // 2. Prevent greedy stretching if the panel has empty space.
        Layout.maximumWidth: Layout.minimumWidth 

        TextMetrics {
            id: dummyMetrics
            font.family: interFont.name 
            font.pixelSize: panelRoot.fSize
            text: "↓  999.99 MB/s" // Widest possible expected string
        }

        // 3. GridLayout ensures perfect alignment between arrows and values
        GridLayout {
            anchors.centerIn: parent
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: 0 // Stack rows tightly

            // Row 1: Download
            Text {
                text: "↓"
                font.pixelSize: panelRoot.fSize
                color: Kirigami.Theme.positiveTextColor
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            }
            Text {
                text: root.fmt(root.downloadSpeed)
                font.pixelSize: panelRoot.fSize
                font.family: interFont.name // Apply your custom font
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
            }

            // Row 2: Upload
            Text {
                text: "↑"
                font.pixelSize: panelRoot.fSize
                color: Kirigami.Theme.positiveTextColor
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            }
            Text {
                text: root.fmt(root.uploadSpeed)
                font.pixelSize: panelRoot.fSize
                font.family: interFont.name // Apply your custom font
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // Full representation — expanded / desktop view
    // ══════════════════════════════════════════════════════════════════════
    fullRepresentation: Item {
        implicitWidth:  Kirigami.Units.gridUnit * 14
        implicitHeight: Kirigami.Units.gridUnit * 6

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Text {
                Layout.alignment:   Qt.AlignHCenter
                text:               "Today's Usage"
                font.family:        interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                font.pixelSize:     Kirigami.Units.gridUnit * 0.85
                font.weight:        Font.SemiBold
                font.letterSpacing: 1.2
                color:              Kirigami.Theme.disabledTextColor
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
                    text:           root.fmt(root.dailyDownload)
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
                    color:          Kirigami.Theme.positiveTextColor
                }
                Text {
                    text:           root.fmt(root.dailyUpload)
                    font.family:    interFont.status === FontLoader.Ready ? "Inter" : "sans-serif"
                    font.pixelSize: Kirigami.Units.gridUnit * 1.4
                    font.weight:    Font.Medium
                    color:          Kirigami.Theme.textColor
                }
            }
        }
    }
}
