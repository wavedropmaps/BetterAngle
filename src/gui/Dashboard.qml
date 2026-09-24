import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Item {
    id: root

    // ── Shared building blocks ──────────────────────────────────────────
    // Inline components keep every tab on the same look without repeating
    // 30 lines of styling per control. Colours are literal on purpose:
    // inline components can't see ids from this file.

    component SectionHeader: Text {
        color: "#6a6a82"
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1
    }

    component Hint: Text {
        width: parent ? parent.width : 0
        color: "#7a7a90"
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }

    // Rounded panel that stacks its children vertically.
    component Card: Rectangle {
        default property alias content: cardColumn.data
        property alias spacing: cardColumn.spacing
        width: parent ? parent.width : 0
        height: cardColumn.implicitHeight + 28
        radius: 8
        color: "#14141d"
        border.color: "#24243a"
        border.width: 1
        Column {
            id: cardColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10
        }
    }

    component ActionButton: Button {
        id: btn
        property color baseColor: "#2a2a3e"
        property color hoverColor: Qt.lighter(baseColor, 1.25)
        property color borderColor: "transparent"
        implicitHeight: 36
        font.bold: true
        font.pixelSize: 12
        contentItem: Text {
            text: btn.text
            font: btn.font
            color: "white"
            opacity: btn.enabled ? 1.0 : 0.45
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 6
            color: btn.down ? Qt.darker(btn.baseColor, 1.2)
                            : (btn.hovered ? btn.hoverColor : btn.baseColor)
            border.color: btn.visualFocus ? "#00ffcc" : btn.borderColor
            border.width: 1
            opacity: btn.enabled ? 1.0 : 0.5
        }
    }

    component DarkField: TextField {
        id: fld
        implicitHeight: 34
        color: "white"
        selectionColor: "#00cca3"
        placeholderTextColor: "#5a5a70"
        font.pixelSize: 13
        leftPadding: 10
        background: Rectangle {
            radius: 6
            color: "#1b1b2a"
            border.color: fld.activeFocus ? "#00cca3" : "#2e2e46"
            border.width: fld.activeFocus ? 2 : 1
        }
    }

    component DarkCombo: ComboBox {
        id: combo
        implicitHeight: 34
        font.pixelSize: 13
        contentItem: Text {
            leftPadding: 10
            rightPadding: combo.indicator.width + 6
            text: combo.displayText
            font: combo.font
            color: "white"
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: Text {
            x: combo.width - width - 12
            y: (combo.height - height) / 2
            text: "▾"
            color: "#8a8aa0"
            font.pixelSize: 12
        }
        background: Rectangle {
            radius: 6
            color: combo.hovered ? "#20203a" : "#1b1b2a"
            border.color: combo.activeFocus || combo.popup.visible ? "#00cca3" : "#2e2e46"
            border.width: 1
        }
        delegate: ItemDelegate {
            width: combo.width
            highlighted: combo.highlightedIndex === index
            contentItem: Text {
                text: modelData
                color: "white"
                font.pixelSize: 13
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { color: highlighted ? "#2a2a45" : "#1b1b2a" }
        }
        popup: Popup {
            y: combo.height + 2
            width: combo.width
            implicitHeight: Math.min(contentItem.implicitHeight + 2, 240)
            padding: 1
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: combo.popup.visible ? combo.delegateModel : null
                currentIndex: combo.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator {}
            }
            background: Rectangle { color: "#1b1b2a"; radius: 6; border.color: "#2e2e46" }
        }
    }

    component DarkSlider: Slider {
        id: sl
        implicitHeight: 28
        background: Rectangle {
            x: sl.leftPadding
            y: sl.topPadding + sl.availableHeight / 2 - height / 2
            width: sl.availableWidth
            height: 4
            radius: 2
            color: "#2e2e46"
            Rectangle {
                width: sl.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: "#00cca3"
            }
        }
        handle: Rectangle {
            x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
            y: sl.topPadding + sl.availableHeight / 2 - height / 2
            width: 16; height: 16; radius: 8
            color: sl.pressed ? "#00ffcc" : "#e8e8f0"
            border.color: "#00cca3"
            border.width: 2
        }
    }

    component DarkSwitch: Switch {
        id: sw
        indicator: Rectangle {
            implicitWidth: 38; implicitHeight: 20
            x: sw.leftPadding
            y: (sw.height - height) / 2
            radius: 10
            color: sw.checked ? "#00a382" : "#2e2e46"
            border.color: sw.checked ? "#00cca3" : "#3a3a55"
            Rectangle {
                x: sw.checked ? parent.width - width - 3 : 3
                y: 3
                width: 14; height: 14; radius: 7
                color: "white"
                Behavior on x { NumberAnimation { duration: 120 } }
            }
        }
        contentItem: Text {
            leftPadding: sw.indicator.width + 10
            text: sw.text
            color: "#e8e8f0"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
    }

    // Label on the left, value on the right (Debug tab).
    component StatRow: RowLayout {
        property string label
        property string value
        property color valueColor: "#e8e8f0"
        width: parent ? parent.width : 0
        Text { text: parent.label; color: "#9a9ab0"; font.pixelSize: 12; Layout.fillWidth: true }
        Text { text: parent.value; color: parent.valueColor; font.bold: true; font.pixelSize: 12 }
    }

    // Selectable option card for a two-way choice (transition input mode).
    component OptionCard: Rectangle {
        id: opt
        property bool selected: false
        property string title
        property string subtitle
        property string body
        signal clicked()
        width: parent ? parent.width : 0
        height: optCol.implicitHeight + 20
        radius: 8
        color: selected ? "#10261f" : (optMouse.containsMouse ? "#191926" : "#14141d")
        border.color: selected ? "#00cca3" : "#2e2e46"
        border.width: selected ? 2 : 1
        Column {
            id: optCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; leftMargin: 34 }
            spacing: 3
            Text { text: opt.title; color: "white"; font.bold: true; font.pixelSize: 13 }
            Text { text: opt.subtitle; color: opt.selected ? "#00ffcc" : "#8a8aa0"; font.pixelSize: 11; font.bold: true }
            Text { text: opt.body; color: "#9a9ab0"; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
        }
        // Radio dot
        Rectangle {
            x: 11; y: 12
            width: 14; height: 14; radius: 7
            color: "transparent"
            border.color: opt.selected ? "#00cca3" : "#5a5a70"
            border.width: 2
            Rectangle {
                anchors.centerIn: parent
                width: 6; height: 6; radius: 3
                color: "#00ffcc"
                visible: opt.selected
            }
        }
        MouseArea {
            id: optMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: opt.clicked()
        }
    }

    // Diagnostic kill-switch with a description (Debug tab).
    component DiagToggle: Rectangle {
        id: diag
        property bool checked: false
        property string onText
        property string offText
        property string description
        signal toggled(bool value)
        width: parent ? parent.width : 0
        height: diagCol.implicitHeight + 16
        radius: 6
        color: checked ? "#2a1010" : "#101a14"
        border.color: checked ? "#ff4444" : "#224433"
        border.width: 1
        Column {
            id: diagCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 2
            DarkSwitch {
                checked: diag.checked
                text: diag.checked ? diag.onText : diag.offText
                onToggled: diag.toggled(checked)
            }
            Text {
                text: diag.description
                color: "#7a7a90"; font.pixelSize: 10
                width: parent.width; wrapMode: Text.WordWrap
            }
        }
    }

    // One hotkey binding: click the field, then press a key combo or mouse
    // button. Emits bound(text) with e.g. "Ctrl + U" or "Mouse4".
    component HotkeyRow: RowLayout {
        id: hk
        property string label
        property string value
        signal bound(string bind)
        width: parent ? parent.width : 0
        spacing: 10

        function modifierParts(mods) {
            var parts = []
            if (mods & Qt.ControlModifier) parts.push("Ctrl")
            if (mods & Qt.ShiftModifier) parts.push("Shift")
            if (mods & Qt.AltModifier) parts.push("Alt")
            if (mods & Qt.MetaModifier) parts.push("Win")
            return parts
        }

        function keyName(event) {
            var k = event.key
            var keypad = (event.modifiers & Qt.KeypadModifier)
            if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1)
            if (keypad && k >= Qt.Key_0 && k <= Qt.Key_9) return "Numpad" + String.fromCharCode(k)
            if (keypad && k === Qt.Key_Plus) return "Add"
            if (keypad && k === Qt.Key_Minus) return "Subtract"
            if (keypad && k === Qt.Key_Asterisk) return "Multiply"
            if (keypad && k === Qt.Key_Slash) return "Divide"
            if (keypad && (k === Qt.Key_Period || k === Qt.Key_Comma)) return "Decimal"
            var named = {}
            named[Qt.Key_Space] = "Space"; named[Qt.Key_Tab] = "Tab"
            named[Qt.Key_Return] = "Enter"; named[Qt.Key_Enter] = "Enter"
            named[Qt.Key_Backspace] = "Backspace"; named[Qt.Key_Insert] = "Insert"
            named[Qt.Key_Delete] = "Delete"; named[Qt.Key_Home] = "Home"
            named[Qt.Key_End] = "End"; named[Qt.Key_PageUp] = "PageUp"
            named[Qt.Key_PageDown] = "PageDown"; named[Qt.Key_Up] = "Up"
            named[Qt.Key_Down] = "Down"; named[Qt.Key_Left] = "Left"
            named[Qt.Key_Right] = "Right"; named[Qt.Key_CapsLock] = "CapsLock"
            named[Qt.Key_NumLock] = "NumLock"; named[Qt.Key_ScrollLock] = "ScrollLock"
            named[Qt.Key_Print] = "PrintScreen"; named[Qt.Key_Pause] = "Pause"
            if (named[k] !== undefined) return named[k]
            if ((k >= Qt.Key_A && k <= Qt.Key_Z) || (k >= Qt.Key_0 && k <= Qt.Key_9))
                return String.fromCharCode(k)
            return ""
        }

        function mouseName(button) {
            if (button === Qt.LeftButton) return "Mouse1"
            if (button === Qt.RightButton) return "Mouse2"
            if (button === Qt.MiddleButton) return "Mouse3"
            if (button === Qt.BackButton) return "Mouse4"
            if (button === Qt.ForwardButton) return "Mouse5"
            return ""
        }

        function commit(parts) {
            hk.bound(parts.join(" + "))
            backend.saveKeybinds()
            field.focus = false
        }

        Text {
            text: hk.label
            color: "#c8c8d4"
            font.pixelSize: 12
            Layout.preferredWidth: 130
        }
        DarkField {
            id: field
            Layout.fillWidth: true
            readOnly: true
            selectByMouse: false
            activeFocusOnTab: true
            text: activeFocus ? "Press a key or mouse button…" : hk.value
            color: activeFocus ? "#00ffcc" : "white"
            font.bold: activeFocus

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) {
                    if (!field.activeFocus) {
                        field.forceActiveFocus()
                        return
                    }
                    var name = hk.mouseName(mouse.button)
                    if (name === "") return
                    var parts = hk.modifierParts(mouse.modifiers)
                    parts.push(name)
                    hk.commit(parts)
                }
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                event.accepted = true
                if (event.key === Qt.Key_Escape) {
                    field.focus = false
                    return
                }
                if (event.key === Qt.Key_Control || event.key === Qt.Key_Shift ||
                    event.key === Qt.Key_Alt || event.key === Qt.Key_Meta)
                    return
                var name = hk.keyName(event)
                if (name === "") return
                var parts = hk.modifierParts(event.modifiers)
                parts.push(name)
                hk.commit(parts)
            }
            onActiveFocusChanged: {
                if (activeFocus) backend.startKeybindAssignment()
                else backend.endKeybindAssignment()
            }
        }
    }

    component TabBtn: TabButton {
        id: tb
        contentItem: Text {
            text: tb.text
            color: tb.checked ? "#00ffcc" : (tb.hovered ? "#c8c8d4" : "#7a7a90")
            font.bold: true
            font.pixelSize: 12
            font.letterSpacing: 1
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: tb.checked ? "#16162a" : "transparent"
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 2
                color: "#00ffcc"
                visible: tb.checked
            }
        }
    }

    // ── Layout ──────────────────────────────────────────────────────────

    // Debug values are polled, not pushed. 10 Hz is plenty for a readout and
    // only runs while the Debug tab is open.
    Timer {
        interval: 100
        running: bar.currentIndex === 3
        repeat: true
        onTriggered: backend.refreshDebugData()
    }

    TabBar {
        id: bar
        width: parent.width
        background: Rectangle { color: "#0d0d12" }
        onCurrentIndexChanged: {
            if (currentIndex === 2 && !backend.hasCheckedForUpdates)
                backend.checkForUpdates()
        }
        TabBtn { text: qsTr("GENERAL") }
        TabBtn { text: qsTr("CROSSHAIR") }
        TabBtn { text: qsTr("UPDATES") }
        TabBtn { text: qsTr("DEBUG") }
    }

    StackLayout {
        width: parent.width
        anchors.top: bar.bottom
        anchors.bottom: parent.bottom
        currentIndex: bar.currentIndex

        // ─── GENERAL ────────────────────────────────────────────────
        Rectangle {
            color: "#0d0d12"
            Flickable {
                anchors.fill: parent
                contentHeight: genCol.implicitHeight + 32
                clip: true
                ScrollBar.vertical: ScrollBar {}
                Column {
                    id: genCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 12

                    // Angle
                    Card {
                        SectionHeader { text: "ANGLE" }
                        ActionButton {
                            text: "RESET ANGLE TO 0"
                            width: parent.width
                            implicitHeight: 42
                            baseColor: "#00a382"
                            hoverColor: "#00cca3"
                            borderColor: "#00ffa3"
                            onClicked: backend.setZero()
                        }
                        Row {
                            width: parent.width
                            spacing: 10
                            Column {
                                width: (parent.width - 10) / 2
                                spacing: 4
                                Text { text: "Fortnite Sens X"; color: "#9a9ab0"; font.pixelSize: 12 }
                                DarkField {
                                    id: sensXField
                                    width: parent.width
                                    text: backend.sensX.toFixed(1)
                                    onEditingFinished: {
                                        var v = parseFloat(text.replace(",", "."))
                                        if (!isNaN(v) && v > 0) backend.sensX = Number(v.toFixed(1))
                                        else text = backend.sensX.toFixed(1)
                                    }
                                }
                            }
                            Column {
                                width: (parent.width - 10) / 2
                                spacing: 4
                                Text { text: "Fortnite Sens Y"; color: "#9a9ab0"; font.pixelSize: 12 }
                                DarkField {
                                    id: sensYField
                                    width: parent.width
                                    text: backend.sensY.toFixed(1)
                                    onEditingFinished: {
                                        var v = parseFloat(text.replace(",", "."))
                                        if (!isNaN(v) && v > 0) backend.sensY = Number(v.toFixed(1))
                                        else text = backend.sensY.toFixed(1)
                                    }
                                }
                            }
                        }
                        Connections {
                            target: backend
                            // Re-read so the fields always show the loaded profile.
                            function onProfileChanged() {
                                sensXField.text = backend.sensX.toFixed(1)
                                sensYField.text = backend.sensY.toFixed(1)
                            }
                        }
                    }

                    // Transition input handling
                    Card {
                        SectionHeader { text: "DIVE / GLIDE TRANSITIONS" }
                        Hint {
                            text: "Fortnite changes turn speed for ~0.7s whenever you switch between diving and gliding. Choose how BetterAngle handles that window."
                        }
                        OptionCard {
                            title: "Block input"
                            subtitle: "EXACT ANGLE · CLASSIC"
                            body: "Freezes mouse and keyboard during the change so nothing can move. The angle stays exact, but a key you let go of during the freeze can stay stuck (ghost walking)."
                            selected: backend.inputLockMode === 0
                            onClicked: backend.inputLockMode = 0
                        }
                        OptionCard {
                            title: "Blend (no lock)"
                            subtitle: "SMOOTH MOVEMENT · ESTIMATED DURING CHANGE"
                            body: "Never touches your input, so movement always works. The angle eases between glide and dive speed instead. If you move the mouse mid-change the HUD shows “~ ESTIMATED” until you reset the angle."
                            selected: backend.inputLockMode === 1
                            onClicked: backend.inputLockMode = 1
                        }
                        Column {
                            width: parent.width
                            spacing: 2
                            visible: backend.inputLockMode === 1
                            RowLayout {
                                width: parent.width
                                Text { text: "Blend duration"; color: "#c8c8d4"; font.pixelSize: 12; Layout.fillWidth: true }
                                Text { text: backend.transitionBlendMs + " ms"; color: "#00ffcc"; font.bold: true; font.pixelSize: 12 }
                            }
                            DarkSlider {
                                width: parent.width
                                from: 100; to: 2000; stepSize: 50
                                value: backend.transitionBlendMs
                                onMoved: backend.transitionBlendMs = Math.round(value)
                            }
                            Hint { text: "Match this to how long the camera takes to settle after a change. 700 ms suits most setups." }
                        }
                    }

                    // Display
                    Card {
                        SectionHeader { text: "DISPLAY" }
                        Text { text: "Game monitor"; color: "#9a9ab0"; font.pixelSize: 12 }
                        DarkCombo {
                            id: monitorCombo
                            width: parent.width
                            model: backend.availableScreens
                            currentIndex: backend.screenIndex
                            onActivated: function(index) { backend.screenIndex = index }
                            Connections {
                                target: backend
                                function onProfileChanged() { monitorCombo.currentIndex = backend.screenIndex }
                            }
                        }
                        Text { text: "HUD decimal places"; color: "#9a9ab0"; font.pixelSize: 12 }
                        DarkCombo {
                            id: decimalCombo
                            width: parent.width
                            model: ["1 decimal place", "2 decimal places"]
                            currentIndex: backend.hudDecimalPlaces - 1
                            onActivated: function(index) { backend.hudDecimalPlaces = index + 1 }
                            Connections {
                                target: backend
                                function onProfileChanged() { decimalCombo.currentIndex = backend.hudDecimalPlaces - 1 }
                            }
                        }
                        ActionButton {
                            text: "RESET HUD POSITION"
                            width: parent.width
                            baseColor: "#1e1228"
                            hoverColor: "#332233"
                            borderColor: "#9944cc"
                            onClicked: backend.resetHudPosition()
                        }
                    }

                    // Detection
                    Card {
                        SectionHeader { text: "DIVE DETECTION" }
                        RowLayout {
                            width: parent.width
                            Text { text: "Match threshold"; color: "#c8c8d4"; font.pixelSize: 12; Layout.fillWidth: true }
                            Text { text: Math.round(backend.diveGlideMatch) + "%"; color: "#00ffcc"; font.bold: true; font.pixelSize: 12 }
                        }
                        DarkSlider {
                            width: parent.width
                            from: 1; to: 20; stepSize: 1
                            value: backend.diveGlideMatch
                            onMoved: backend.diveGlideMatch = value
                        }
                        Hint { text: "Share of the selected area that must match the target colour to count as diving." }

                        RowLayout {
                            width: parent.width
                            spacing: 10
                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: backend.targetColor
                                border.color: "#3a3a55"; border.width: 1
                            }
                            Text { text: "Colour tolerance"; color: "#c8c8d4"; font.pixelSize: 12; Layout.fillWidth: true }
                            Text { text: "±" + backend.tolerance; color: "#00ffcc"; font.bold: true; font.pixelSize: 12 }
                        }
                        DarkSlider {
                            width: parent.width
                            from: 0; to: 120; stepSize: 1
                            value: backend.tolerance
                            onMoved: backend.tolerance = Math.round(value)
                        }
                        Hint { text: "Set the area and colour in-game with the Selection Overlay hotkey." }
                    }

                    // Hotkeys
                    Card {
                        SectionHeader { text: "HOTKEYS" }
                        HotkeyRow {
                            label: "Toggle dashboard"
                            value: backend.keyToggle
                            onBound: function(bind) { backend.keyToggle = bind }
                        }
                        HotkeyRow {
                            label: "Selection overlay"
                            value: backend.keyRoi
                            onBound: function(bind) { backend.keyRoi = bind }
                        }
                        HotkeyRow {
                            label: "Toggle crosshair"
                            value: backend.keyCross
                            onBound: function(bind) { backend.keyCross = bind }
                        }
                        HotkeyRow {
                            label: "Zero angle"
                            value: backend.keyZero
                            onBound: function(bind) { backend.keyZero = bind }
                        }
                        Hint { text: "Click a bind, then press the combo (keyboard or Mouse1–5). Esc cancels. Changes apply immediately." }
                    }

                    ActionButton {
                        text: "QUIT APP"
                        width: parent.width
                        baseColor: "#b52e2e"
                        hoverColor: "#e63939"
                        onClicked: backend.terminateApp()
                    }
                }
            }
        }

        // ─── CROSSHAIR ──────────────────────────────────────────────
        Rectangle {
            color: "#0d0d12"
            Flickable {
                anchors.fill: parent
                contentHeight: crossCol.implicitHeight + 32
                clip: true
                ScrollBar.vertical: ScrollBar {}
                Column {
                    id: crossCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 12

                    Card {
                        SectionHeader { text: "CROSSHAIR" }
                        ActionButton {
                            text: backend.crosshairOn ? "CROSSHAIR: ON" : "CROSSHAIR: OFF"
                            width: parent.width
                            baseColor: backend.crosshairOn ? "#00a382" : "#2a2a3e"
                            hoverColor: backend.crosshairOn ? "#00cca3" : "#3a3a52"
                            onClicked: backend.crosshairOn = !backend.crosshairOn
                        }
                        RowLayout {
                            width: parent.width
                            Text { text: "Line thickness"; color: "#c8c8d4"; font.pixelSize: 12; Layout.fillWidth: true }
                            Text { text: Math.round(backend.crossThickness) + " px"; color: "#00ffcc"; font.bold: true; font.pixelSize: 12 }
                        }
                        DarkSlider {
                            width: parent.width
                            from: 1; to: 10; stepSize: 1
                            value: backend.crossThickness
                            onMoved: backend.crossThickness = Math.round(value)
                        }
                        ActionButton {
                            text: backend.crossPulse ? "PULSE ANIMATION: ON" : "PULSE ANIMATION: OFF"
                            width: parent.width
                            enabled: backend.crosshairOn
                            baseColor: backend.crossPulse ? "#4a3080" : "#2a2a3e"
                            borderColor: backend.crossPulse ? "#6644aa" : "transparent"
                            onClicked: backend.crossPulse = !backend.crossPulse
                        }
                    }

                    // ── HSV colour picker ──────────────────────────────
                    Card {
                        SectionHeader { text: "COLOUR" }
                        Item {
                            id: colorPicker
                            width: parent.width
                            height: svCanvas.height + hueStrip.height + hexRow.height + 16

                            // Internal HSV state
                            property real hue: 0.0
                            property real sat: 1.0
                            property real val: 1.0
                            // Pure hue colour for the SV gradient base
                            property color hueColor: Qt.hsva(hue, 1.0, 1.0, 1.0)

                            function initFromBackend() {
                                var c = backend.crossColor
                                var hsv = rgbToHsv(c.r, c.g, c.b)
                                hue = hsv[0]; sat = hsv[1]; val = hsv[2]
                            }

                            function rgbToHsv(r, g, b) {
                                var max = Math.max(r, g, b), min = Math.min(r, g, b)
                                var d = max - min, h = 0, s = max === 0 ? 0 : d / max, v = max
                                if (d !== 0) {
                                    if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6
                                    else if (max === g) h = ((b - r) / d + 2) / 6
                                    else h = ((r - g) / d + 4) / 6
                                }
                                return [h, s, v]
                            }

                            function hsvToRgb(h, s, v) {
                                var i = Math.floor(h * 6), f = h * 6 - i
                                var p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
                                switch (i % 6) {
                                    case 0: return [v, t, p]
                                    case 1: return [q, v, p]
                                    case 2: return [p, v, t]
                                    case 3: return [p, q, v]
                                    case 4: return [t, p, v]
                                    case 5: return [v, p, q]
                                }
                                return [0, 0, 0]
                            }

                            function toHex2(x) {
                                var s = Math.round(x * 255).toString(16)
                                return s.length === 1 ? "0" + s : s
                            }

                            function applyColor() {
                                var rgb = hsvToRgb(hue, sat, val)
                                backend.crossColor = Qt.rgba(rgb[0], rgb[1], rgb[2], 1)
                            }

                            Component.onCompleted: initFromBackend()
                            Connections {
                                target: backend
                                function onCrosshairChanged() { colorPicker.initFromBackend() }
                            }

                            // Saturation / value square
                            Item {
                                id: svCanvas
                                width: parent.width
                                height: Math.min(parent.width * 0.55, 160)

                                Rectangle {
                                    anchors.fill: parent; radius: 6
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "white" }
                                        GradientStop { position: 1.0; color: colorPicker.hueColor }
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: 6
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: "black" }
                                    }
                                }
                                Rectangle {
                                    x: colorPicker.sat * parent.width - width / 2
                                    y: (1 - colorPicker.val) * parent.height - height / 2
                                    width: 12; height: 12; radius: 6
                                    color: "transparent"
                                    border.color: "white"; border.width: 2
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    function pick(mx, my) {
                                        colorPicker.sat = Math.max(0, Math.min(1, mx / svCanvas.width))
                                        colorPicker.val = Math.max(0, Math.min(1, 1 - my / svCanvas.height))
                                        colorPicker.applyColor()
                                    }
                                    onPressed: function(mouse) { pick(mouse.x, mouse.y) }
                                    onPositionChanged: function(mouse) { if (pressed) pick(mouse.x, mouse.y) }
                                }
                            }

                            // Hue strip
                            Item {
                                id: hueStrip
                                anchors.top: svCanvas.bottom; anchors.topMargin: 8
                                width: parent.width; height: 18

                                Rectangle {
                                    anchors.fill: parent; radius: 9
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.000; color: "#ff0000" }
                                        GradientStop { position: 0.167; color: "#ffff00" }
                                        GradientStop { position: 0.333; color: "#00ff00" }
                                        GradientStop { position: 0.500; color: "#00ffff" }
                                        GradientStop { position: 0.667; color: "#0000ff" }
                                        GradientStop { position: 0.833; color: "#ff00ff" }
                                        GradientStop { position: 1.000; color: "#ff0000" }
                                    }
                                }
                                Rectangle {
                                    x: colorPicker.hue * parent.width - width / 2
                                    y: (parent.height - height) / 2
                                    width: 10; height: 22; radius: 5
                                    color: "white"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    function pick(mx) {
                                        colorPicker.hue = Math.max(0, Math.min(1, mx / hueStrip.width))
                                        colorPicker.applyColor()
                                    }
                                    onPressed: function(mouse) { pick(mouse.x) }
                                    onPositionChanged: function(mouse) { if (pressed) pick(mouse.x) }
                                }
                            }

                            // Swatch + hex field
                            Row {
                                id: hexRow
                                anchors.top: hueStrip.bottom; anchors.topMargin: 8
                                width: parent.width; spacing: 10

                                Rectangle {
                                    width: 34; height: 34; radius: 6
                                    color: backend.crossColor
                                    border.color: "#3a3a55"; border.width: 1
                                }
                                DarkField {
                                    id: hexField
                                    width: parent.width - 44
                                    text: "#" + colorPicker.toHex2(backend.crossColor.r) +
                                          colorPicker.toHex2(backend.crossColor.g) +
                                          colorPicker.toHex2(backend.crossColor.b)
                                    onEditingFinished: {
                                        var hex = text.replace("#", "")
                                        if (/^[0-9a-fA-F]{6}$/.test(hex)) {
                                            backend.crossColor = Qt.rgba(parseInt(hex.substr(0, 2), 16) / 255,
                                                                         parseInt(hex.substr(2, 2), 16) / 255,
                                                                         parseInt(hex.substr(4, 2), 16) / 255, 1)
                                            colorPicker.initFromBackend()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Fine position
                    Card {
                        SectionHeader { text: "POSITION" }
                        Repeater {
                            model: [
                                { axis: "X", less: "← −0.5", more: "+0.5 →" },
                                { axis: "Y", less: "↑ −0.5", more: "+0.5 ↓" }
                            ]
                            delegate: RowLayout {
                                width: parent.width
                                spacing: 8
                                Text {
                                    text: modelData.axis + ": " +
                                          (modelData.axis === "X" ? backend.crossOffsetX : backend.crossOffsetY).toFixed(1)
                                    color: "white"; font.pixelSize: 13
                                    Layout.fillWidth: true
                                }
                                ActionButton {
                                    text: modelData.less
                                    Layout.preferredWidth: 90
                                    implicitHeight: 30
                                    font.bold: false
                                    onClicked: {
                                        if (modelData.axis === "X") backend.crossOffsetX = backend.crossOffsetX - 0.5
                                        else backend.crossOffsetY = backend.crossOffsetY - 0.5
                                    }
                                }
                                ActionButton {
                                    text: modelData.more
                                    Layout.preferredWidth: 90
                                    implicitHeight: 30
                                    font.bold: false
                                    onClicked: {
                                        if (modelData.axis === "X") backend.crossOffsetX = backend.crossOffsetX + 0.5
                                        else backend.crossOffsetY = backend.crossOffsetY + 0.5
                                    }
                                }
                            }
                        }
                        Row {
                            width: parent.width
                            spacing: 10
                            ActionButton {
                                text: "SNAP TO CENTER"
                                width: (parent.width - 10) / 2
                                baseColor: "#224ecc"
                                hoverColor: "#3375ee"
                                onClicked: {
                                    backend.crossOffsetX = 0
                                    backend.crossOffsetY = 0
                                }
                            }
                            ActionButton {
                                text: "RESET TO DEFAULTS"
                                width: (parent.width - 10) / 2
                                baseColor: "#8a2222"
                                hoverColor: "#b52e2e"
                                onClicked: backend.resetCrosshairToDefaults()
                            }
                        }
                    }

                    // Saved configs
                    Card {
                        SectionHeader { text: "SAVED CONFIGS" }
                        Row {
                            width: parent.width
                            spacing: 8
                            DarkField {
                                id: presetNameField
                                width: parent.width - 104
                                placeholderText: "Config name…"
                                onAccepted: saveBtn.clicked()
                            }
                            ActionButton {
                                id: saveBtn
                                text: "SAVE"
                                width: 96
                                implicitHeight: 34
                                baseColor: "#224ecc"
                                hoverColor: "#3375ee"
                                enabled: presetNameField.text.trim() !== ""
                                onClicked: {
                                    backend.saveCrosshairPreset(presetNameField.text.trim())
                                    presetNameField.text = ""
                                }
                            }
                        }
                        ListView {
                            id: presetList
                            width: parent.width
                            height: Math.min(count * 38, 190)
                            spacing: 4
                            clip: true
                            model: backend.crosshairPresetNames()
                            Connections {
                                target: backend
                                function onCrosshairPresetsChanged() { presetList.model = backend.crosshairPresetNames() }
                            }
                            delegate: Rectangle {
                                width: presetList.width
                                height: 34
                                radius: 6
                                color: "#1b1b2a"
                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 4 }
                                    spacing: 6
                                    Text {
                                        text: modelData
                                        color: "white"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    ActionButton {
                                        text: "Load"
                                        implicitWidth: 52; implicitHeight: 26
                                        font.pixelSize: 11
                                        baseColor: "#2a7a54"
                                        hoverColor: "#3a9e6e"
                                        onClicked: backend.loadCrosshairPreset(index)
                                    }
                                    ActionButton {
                                        text: "✕"
                                        implicitWidth: 26; implicitHeight: 26
                                        baseColor: "#6a2222"
                                        hoverColor: "#cc3333"
                                        onClicked: backend.deleteCrosshairPreset(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ─── UPDATES ────────────────────────────────────────────────
        Rectangle {
            color: "#0d0d12"
            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 12

                Card {
                    Row {
                        spacing: 10
                        Text {
                            text: "Version " + backend.versionStr
                            color: "white"; font.pixelSize: 18; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: channelLabel.width + 14; height: 20; radius: 4
                            color: backend.betaUpdates ? "#332200" : "#001a0d"
                            border.color: backend.betaUpdates ? "#ccaa00" : "#00aa44"
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                id: channelLabel
                                anchors.centerIn: parent
                                text: backend.betaUpdates ? "BETA" : "STABLE"
                                color: backend.betaUpdates ? "#ffdd44" : "#00ff88"
                                font.bold: true; font.pixelSize: 10
                            }
                        }
                    }
                    Text {
                        text: "Latest online: " + backend.latestVersion
                        color: "#9a9ab0"
                        font.pixelSize: 12
                        visible: backend.hasCheckedForUpdates && backend.latestVersion !== ""
                    }

                    ActionButton {
                        width: parent.width
                        implicitHeight: 44
                        text: {
                            if (backend.isDownloading) return "DOWNLOADING…"
                            if (backend.downloadComplete) return "INSTALL UPDATE"
                            if (backend.isCheckingForUpdates) return "CHECKING…"
                            if (backend.updateStatus === "Downloaded update was invalid. Click to retry.") return "RETRY DOWNLOAD"
                            if (backend.updateAvailable) return "DOWNLOAD UPDATE"
                            if (backend.hasCheckedForUpdates) return "CHECK AGAIN"
                            return "CHECK FOR UPDATES"
                        }
                        enabled: !backend.isDownloading && !backend.isCheckingForUpdates
                        baseColor: backend.downloadComplete ? "#5a3ce0" : "#00a382"
                        hoverColor: backend.downloadComplete ? "#6a4cff" : "#00cca3"
                        onClicked: {
                            if (backend.downloadComplete || backend.updateAvailable)
                                backend.downloadUpdate()
                            else
                                backend.checkForUpdates()
                        }
                    }

                    Row {
                        spacing: 10
                        BusyIndicator {
                            width: 22; height: 22
                            running: backend.isCheckingForUpdates || backend.isDownloading
                            visible: running
                        }
                        Text {
                            text: backend.updateStatus
                            color: {
                                if (backend.downloadComplete) return "#8a70ff"
                                if (backend.updateAvailable) return "#00cca3"
                                if (backend.isDownloading) return "#00ccff"
                                return "#c8c8d4"
                            }
                            font.bold: true
                            font.pixelSize: 13
                            height: 22
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    Hint {
                        text: backend.updateHistory
                        visible: backend.updateHistory !== ""
                    }
                }

                Text {
                    text: "“The best wins begin with the best drops”"
                    color: "#00cca3"
                    font.pixelSize: 13
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    topPadding: 8
                }
            }
        }

        // ─── DEBUG ──────────────────────────────────────────────────
        Rectangle {
            color: "#0d0d12"
            Flickable {
                anchors.fill: parent
                contentHeight: debugRootCol.implicitHeight + 32
                clip: true
                ScrollBar.vertical: ScrollBar {}
                Column {
                    id: debugRootCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 12

                    Card {
                        SectionHeader { text: "DEBUG" }
                        DarkSwitch {
                            text: "Show debug overlay on screen"
                            checked: backend.showDebugOverlay
                            onToggled: backend.showDebugOverlay = checked
                        }
                    }

                    Card {
                        spacing: 7
                        SectionHeader { text: "DETECTION" }
                        StatRow { label: "Scanner delay"; value: backend.detectionDelayMs + " ms"; valueColor: backend.detectionDelayMs < 15 ? "#00ffaa" : "#ff6644" }
                        StatRow { label: "Match ratio"; value: backend.detectionRatioPct + "%"; valueColor: "#00ccff" }
                        StatRow { label: "Peak match (2s)"; value: backend.peakMatchPct + "%"; valueColor: backend.peakMatchPct > 0 ? "#ffaa00" : "#5a5a70" }
                        StatRow { label: "State"; value: backend.isDiving ? "DIVING" : "GLIDING"; valueColor: backend.isDiving ? "#ff5050" : "#50ff80" }
                        StatRow { label: "ROI"; value: backend.roiDimensions; valueColor: "#88aacc" }
                        StatRow { label: "Scanner CPU"; value: backend.scannerCpuPct + "%"; valueColor: backend.scannerCpuPct < 50 ? "#00ffaa" : "#ff6644" }
                    }

                    Card {
                        spacing: 7
                        SectionHeader { text: "TRANSITIONS" }
                        StatRow { label: "Mode"; value: backend.inputLockMode === 1 ? "BLEND (no lock)" : "BLOCK INPUT"; valueColor: "#00ffcc" }
                        StatRow { label: "Input locked now"; value: backend.inputLocked ? "YES" : "NO"; valueColor: backend.inputLocked ? "#cc88ff" : "#5a5a70" }
                        StatRow { label: "Last transition"; value: backend.lockTriggerReason; valueColor: backend.lockTriggerReason !== "None" ? "#ffaa00" : "#5a5a70" }
                        StatRow { label: "Angle"; value: backend.angleEstimated ? "ESTIMATED" : "EXACT"; valueColor: backend.angleEstimated ? "#ffbe46" : "#00ffaa" }
                    }

                    Card {
                        spacing: 7
                        SectionHeader { text: "FORTNITE" }
                        StatRow { label: "Running"; value: backend.fnRunning ? "YES" : "NO"; valueColor: backend.fnRunning ? "#00ffcc" : "#ff4c4c" }
                        StatRow { label: "Focused"; value: backend.fnFocused ? "YES" : "NO"; valueColor: backend.fnFocused ? "#00ffcc" : "#ff4c4c" }
                        StatRow { label: "Monitor"; value: backend.fortniteMonitorLabel; valueColor: backend.fnRunning ? "#00ffcc" : "#ff4c4c" }
                        StatRow { label: "Mouse captured"; value: backend.fnMouseHidden ? "YES" : "NO"; valueColor: backend.fnMouseHidden ? "#00ffcc" : "#ff4c4c" }
                        Hint { text: "The angle only updates while Fortnite is focused and the mouse is captured (cursor hidden)." }
                    }

                    Card {
                        spacing: 7
                        SectionHeader { text: "KEY STATE MONITOR" }
                        StatRow { label: "Physical / tracked"; value: backend.physicalKeyStates; valueColor: "#00ffa3" }
                        StatRow { label: "Raw W key"; value: backend.rawWState; valueColor: "#00ffa3" }
                        StatRow { label: "Stuck-key check"; value: backend.ghostMismatch ? "MISMATCH" : "OK"; valueColor: backend.ghostMismatch ? "#ff4c4c" : "#00ffaa" }
                        Hint { text: "A mismatch means Windows thinks a key is held that isn't physically down — the ghost-walk symptom of Block Input mode." }
                    }

                    Card {
                        spacing: 7
                        SectionHeader { text: "HUD" }
                        StatRow { label: "HUD position"; value: "(" + backend.hudX + ", " + backend.hudY + ")"; valueColor: "#88ccff" }
                        StatRow { label: "Active monitor"; value: "Monitor " + (backend.screenIndex + 1); valueColor: "#88ccff" }
                        Hint { text: "Move the angle box in-game: hold Ctrl, then click and drag it. Release to save." }
                    }

                    Card {
                        SectionHeader { text: "AUTO-MANTLE DIAGNOSTICS"; color: "#ff6644" }
                        Hint {
                            text: "Test one at a time. ON = that feature is disabled. If auto-mantling stops, that switch is the culprit. Restart BetterAngle after toggling."
                            color: "#aa7755"
                        }
                        DiagToggle {
                            checked: backend.diagNoRawInput
                            onText: "Raw input sink: DISABLED"
                            offText: "Raw input sink: normal"
                            description: "Disables the background mouse listener (RegisterRawInputDevices). Angle tracking stops."
                            onToggled: function(value) { backend.diagNoRawInput = value }
                        }
                        DiagToggle {
                            checked: backend.diagNoTopmost
                            onText: "Topmost overlay: DISABLED"
                            offText: "Topmost overlay: normal"
                            description: "Removes HWND_TOPMOST from the overlay. The HUD may go behind Fortnite in fullscreen."
                            onToggled: function(value) { backend.diagNoTopmost = value }
                        }
                        DiagToggle {
                            checked: backend.diagNoTimer
                            onText: "1ms timer: DISABLED"
                            offText: "1ms timer: normal"
                            description: "Stops forcing 1ms Windows timer resolution (timeBeginPeriod). Polling may become jittery."
                            onToggled: function(value) { backend.diagNoTimer = value }
                        }
                    }

                    Card {
                        SectionHeader { text: "UPDATE CHANNEL" }
                        DarkSwitch {
                            text: backend.betaUpdates ? "Beta channel" : "Stable channel"
                            checked: backend.betaUpdates
                            onToggled: backend.betaUpdates = checked
                        }
                        Hint {
                            text: backend.betaUpdates
                                  ? "Shows every release including pre-releases. You may get unstable builds."
                                  : "Only offers full releases (no pre-releases)."
                        }
                    }
                }
            }
        }
    }
}
