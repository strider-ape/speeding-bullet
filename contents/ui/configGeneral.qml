import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_fontSizeScale: fontSizeSlider.value

    RowLayout {
        Kirigami.FormData.label: "Font Size Scale:"

        Slider {
            id: fontSizeSlider
            from: 0.5
            to: 2.0
            stepSize: 0.05
        }

        Label {
            text: Math.round(fontSizeSlider.value * 100) + "%"
        }
    }
}
