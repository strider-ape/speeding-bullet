import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_fontSizeScale: fontSizeSlider.value

    RowLayout {
        Kirigami.FormData.label: "Text Size:"
        Layout.fillWidth: true

        Slider {
            id: fontSizeSlider
            from: 0.5
            to: 2.0
            stepSize: 0.05
            Layout.fillWidth: true
        }

        SpinBox {
            from: 50
            to: 200
            stepSize: 5
            
            // Sync with the slider value
            value: Math.round(fontSizeSlider.value * 100)
            
            // Show the % symbol inside the spinbox
            textFromValue: function(value, locale) {
                return value + " %";
            }
            valueFromText: function(text, locale) {
                return parseInt(text) || 100;
            }
            
            // Update slider when spinbox is changed
            onValueModified: {
                fontSizeSlider.value = value / 100.0
            }
        }
        
        Button {
            icon.name: "edit-reset"
            text: "Reset"
            visible: fontSizeSlider.value !== 1.0
            onClicked: fontSizeSlider.value = 1.0
            ToolTip.visible: hovered
            ToolTip.text: "Reset to default size (100%)"
        }
    }
}
