/*
    SPDX-FileCopyrightText: 2026 devded
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQml

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // The helper script ships inside the applet package, so the applet
    // keeps working even when ~/.local/bin is not in plasmashell's PATH.
    readonly property string helperPath: decodeURIComponent(
        Qt.resolvedUrl("../code/smooth-zoom").toString().replace(/^file:\/\//, ""))

    readonly property var modifierValues: ["Meta", "Meta+Control", "Meta+Alt", "Control+Alt"]
    readonly property var modifierLabels: ["Super", "Super + Ctrl", "Super + Alt", "Ctrl + Alt"]

    property bool effectLoaded: false
    property real zoomFactor: 1.15
    property int trackingIndex: 0
    property int modifierIndex: 0

    Plasmoid.icon: "zoom-in"
    Plasmoid.title: i18n("Smooth Zoom")
    toolTipMainText: i18n("Smooth Zoom")
    toolTipSubText: effectLoaded
        ? i18n("On — hold Super and scroll up/down")
        : i18n("Off")
    Plasmoid.status: effectLoaded
        ? PlasmaCore.Types.ActiveStatus
        : PlasmaCore.Types.PassiveStatus

    function runHelper(args) {
        executable.connectSource("/usr/bin/bash " + JSON.stringify(helperPath) + " " + args);
    }

    function refresh() {
        runHelper("status");
    }

    function parseStatus(output) {
        const values = {};
        output.split("\n").forEach(line => {
            const pos = line.indexOf("=");
            if (pos > 0)
                values[line.substring(0, pos)] = line.substring(pos + 1);
        });

        effectLoaded = values.loaded === "true";

        if (values.factor !== undefined)
            zoomFactor = Number(values.factor);

        switch (values.tracking_name) {
        case "proportional":     trackingIndex = 0; break;
        case "centered":         trackingIndex = 1; break;
        case "centered-strict":  trackingIndex = 2; break;
        case "push":             trackingIndex = 3; break;
        default:                 trackingIndex = 0; break;
        }

        modifierIndex = modifierValues.indexOf(values.modifier);
    }

    function setFactor(value) {
        runHelper("set --factor " + Number(value).toFixed(2));
    }

    function setTracking(index) {
        const modes = ["proportional", "centered", "centered-strict", "push"];
        if (index >= 0 && index < modes.length)
            runHelper("set --tracking " + modes[index]);
    }

    function setModifier(index) {
        if (index >= 0 && index < modifierValues.length)
            runHelper("set --modifier " + modifierValues[index]);
    }

    function toggle() {
        runHelper("toggle");
    }

    function reset() {
        runHelper("reset");
    }

    function zoomIn() {
        runHelper("zoom-in");
    }

    function zoomOut() {
        runHelper("zoom-out");
    }

    function openSettings() {
        runHelper("settings");
    }

    Component.onCompleted: refresh()

    onExpandedChanged: {
        if (root.expanded)
            refresh();
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            disconnectSource(source);
            const stdout = (data.stdout || "").trim();
            const stderr = (data.stderr || "").trim();

            if (source.indexOf(" status") !== -1)
                root.parseStatus(stdout);
            else
                root.refresh();

            if (data.exitCode !== 0 && stderr.length > 0)
                console.warn("[smooth-zoom]", stderr);
        }

        function exec(command) {
            connectSource(command);
        }
    }

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.small
        implicitHeight: Kirigami.Units.iconSizes.small
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        Layout.preferredHeight: Kirigami.Units.iconSizes.small

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            source: "zoom-in"
            opacity: root.effectLoaded ? 1.0 : 0.45
        }

        Rectangle {
            visible: root.effectLoaded
            width: Math.max(3, Kirigami.Units.smallSpacing)
            height: width
            radius: width / 2
            color: Kirigami.Theme.positiveTextColor
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 22
        implicitHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "zoom-in"
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
                }

                ColumnLayout {
                    spacing: 0
                    PlasmaComponents3.Label {
                        text: i18n("Smooth Zoom")
                        font.bold: true
                    }
                    PlasmaComponents3.Label {
                        text: root.effectLoaded ? i18n("On") : i18n("Off")
                        font: Kirigami.Theme.smallFont
                        opacity: 0.7
                        color: root.effectLoaded
                            ? Kirigami.Theme.positiveTextColor
                            : Kirigami.Theme.disabledTextColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Switch {
                    id: zoomSwitch
                    checked: root.effectLoaded
                    onClicked: root.toggle()
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: i18n("Zoom step")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                }

                PlasmaComponents3.Slider {
                    id: factorSlider
                    Layout.fillWidth: true
                    from: 1.05
                    to: 4.0
                    stepSize: 0.05
                    value: root.zoomFactor
                    onPressedChanged: {
                        if (!pressed)
                            root.setFactor(value);
                    }
                }

                PlasmaComponents3.Label {
                    text: factorSlider.value.toFixed(2) + "×"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    horizontalAlignment: Text.AlignRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: i18n("Pointer tracking")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                }

                QQC2.ComboBox {
                    id: trackingCombo
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 11

                    model: [
                        i18n("Proportional"),
                        i18n("Centered"),
                        i18n("Centered (Strict)"),
                        i18n("Push")
                    ]
                    currentIndex: root.trackingIndex
                    onActivated: index => {
                        root.trackingIndex = index;
                        root.setTracking(index);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Label {
                    text: i18n("Scroll modifier")
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                }

                QQC2.ComboBox {
                    id: modifierCombo
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 11

                    model: root.modifierLabels
                    currentIndex: root.modifierIndex
                    onActivated: index => {
                        root.modifierIndex = index;
                        root.setModifier(index);
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.ToolButton {
                    icon.name: "zoom-out"
                    text: i18n("Zoom out")
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    onClicked: root.zoomOut()
                }

                PlasmaComponents3.ToolButton {
                    icon.name: "zoom-in"
                    text: i18n("Zoom in")
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    onClicked: root.zoomIn()
                }

                Item {
                    Layout.fillWidth: true
                }

                PlasmaComponents3.Label {
                    text: i18n("Hold Super + scroll ↑/↓")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: i18n("Reset 100%")
                    icon.name: "zoom-fit-best"
                    onClicked: root.reset()
                }

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: i18n("Settings")
                    icon.name: "settings-configure"
                    onClicked: root.openSettings()
                }
            }
        }
    }
}
