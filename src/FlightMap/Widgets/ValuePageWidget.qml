/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Dialogs  1.2
import QtQuick.Layouts  1.2

import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Palette       1.0
import QGroundControl               1.0

/// Value page for InstrumentPanel PageView
Column {
    id:         _largeColumn
    width:      pageWidth
    spacing:    _margins

    property bool showSettingsIcon: true

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _margins:       ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id:qgcPal; colorGroupEnabled: true }

    ValuesWidgetController {
        id: controller
    }

    function showSettings() {
        mainWindow.showComponentDialog(propertyPicker, qsTr("Value Widget Setup"), mainWindow.showDialogDefaultWidth, StandardButton.Ok)
    }

    function listContains(list, value) {
        for (var i=0; i<list.length; i++) {
            if (list[i] === value) {
                return true
            }
        }
        return false
    }

    Repeater {
        model: _activeVehicle ? controller.largeValues : 0
        Loader {
            sourceComponent: fact ? largeValue : undefined
            property Fact fact: _activeVehicle.getFact(modelData.replace("Vehicle.", ""))
        }
    } // Repeater - Large

    Flow {
        id:                 _smallFlow
        width:              parent.width
        layoutDirection:    Qt.LeftToRight
        spacing:            _margins

        Repeater {
            model: _activeVehicle ? controller.smallValues : 0
            Loader {
                sourceComponent: fact ? smallValue : undefined
                property Fact fact: _activeVehicle.getFact(modelData.replace("Vehicle.", ""))
            }
        } // Repeater - Small
    } // Flow

    Component {
        id: largeValue

        Column {
            width:  _largeColumn.width
            property bool largeValue: listContains(controller.altitudeProperties, fact.name)

            QGCLabel {
                width:                  parent.width
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                text:                   fact.shortDescription + (fact.units ? " (" + fact.units + ")" : "")
            }
            QGCLabel {
                width:                  parent.width
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.mediumFontPointSize * (largeValue ? 1.3 : 1.0)
                font.family:            largeValue ? ScreenTools.demiboldFontFamily : ScreenTools.normalFontFamily
                fontSizeMode:           Text.HorizontalFit
                text:                   fact.enumOrValueString
            }
        }
    }

    Component {
        id: smallValue

        Column {
            width:  (pageWidth / 2) - (_margins / 2) - 0.1
            clip:   true

            QGCLabel {
                width:                  parent.width
                wrapMode:               Text.WordWrap
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.isTinyScreen ? ScreenTools.smallFontPointSize * 0.75 : ScreenTools.smallFontPointSize
                text:                   fact.shortDescription
            }
            QGCLabel {
                width:                  parent.width
                horizontalAlignment:    Text.AlignHCenter
                fontSizeMode:           Text.HorizontalFit
                text:                   fact.enumOrValueString
            }
            QGCLabel {
                width:                  parent.width
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.isTinyScreen ? ScreenTools.smallFontPointSize * 0.75 : ScreenTools.smallFontPointSize
                fontSizeMode:           Text.HorizontalFit
                text:                   fact.units
            }
        }
    }

    Component {
        id: propertyPicker

        QGCViewDialog {
            id: _propertyPickerDialog

            QGCFlickable {
                anchors.fill:       parent
                contentHeight:      column.height
                flickableDirection: Flickable.VerticalFlick
                clip:               true

                Column {
                    id:             column
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        _margins

                    /*
                      Leaving this here for now just in case
                    FactCheckBox {
                        text:       qsTr("Show large compass")
                        fact:       _showLargeCompass
                        visible:    _showLargeCompass.visible

                        property Fact _showLargeCompass: QGroundControl.settingsManager.appSettings.showLargeCompass
                    }
                    */

                    Item {
                        width:  1
                        height: _margins
                    }

                    QGCLabel {
                        id:     _label
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        wrapMode:       Text.WordWrap
                        text:   qsTr("Select the values you want to display:")
                    }

                    Loader {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        sourceComponent:    factGroupList

                        property var    factGroup:     _activeVehicle
                        property string factGroupName: "Vehicle"
                    }

                    Repeater {
                        model: _activeVehicle.factGroupNames

                        Loader {
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            sourceComponent:    factGroupList

                            property var    factGroup:     _activeVehicle.getFactGroup(modelData)
                            property string factGroupName: modelData
                        }

                    }
                }
            }
        }
    }

    Component {
        id: factGroupList

        // You must push in the following properties from the Loader
        // property var factGroup
        // property string factGroupName

        Column {
            spacing:    _margins

            SectionHeader {
                id:             header
                anchors.left:   parent.left
                anchors.right:  parent.right
                text:           factGroupName.charAt(0).toUpperCase() + factGroupName.slice(1)
                checked:        false
            }

            Column {
                spacing:    _margins
                visible:    header.checked

                Repeater {
                    model: factGroup ? factGroup.factNames : 0

                    RowLayout {
                        spacing: _margins
                        visible: factGroup.getFact(modelData).shortDescription !== ""

                        property string propertyName: factGroupName + "." + modelData

                        function removeFromList(list, value) {
                            var newList = []
                            for (var i=0; i<list.length; i++) {
                                if (list[i] !== value) {
                                    newList.push(list[i])
                                }
                            }
                            return newList
                        }

                        function addToList(list, value) {
                            var found = false
                            for (var i=0; i<list.length; i++) {
                                if (list[i] === value) {
                                    found = true
                                    break
                                }
                            }
                            if (!found) {
                                list.push(value)
                            }
                            return list
                        }

                        function updateValues() {
                            if (_addCheckBox.checked) {
                                if (_largeCheckBox.checked) {
                                    controller.largeValues = addToList(controller.largeValues, propertyName)
                                    controller.smallValues = removeFromList(controller.smallValues, propertyName)
                                } else {
                                    controller.smallValues = addToList(controller.smallValues, propertyName)
                                    controller.largeValues = removeFromList(controller.largeValues, propertyName)
                                }
                            } else {
                                controller.largeValues = removeFromList(controller.largeValues, propertyName)
                                controller.smallValues = removeFromList(controller.smallValues, propertyName)
                            }
                        }

                        QGCCheckBox {
                            id:                     _addCheckBox
                            text:                   factGroup.getFact(modelData).shortDescription
                            checked:                listContains(controller.smallValues, propertyName) || _largeCheckBox.checked
                            onClicked:              updateValues()
                            Layout.fillWidth:       true
                            Layout.minimumWidth:    ScreenTools.defaultFontPixelWidth * 20

                            Component.onCompleted: {
                                if (checked) {
                                    header.checked = true
                                }
                            }
                        }

                        QGCCheckBox {
                            id:                     _largeCheckBox
                            text:                   qsTr("Large")
                            checked:                listContains(controller.largeValues, propertyName)
                            enabled:                _addCheckBox.checked
                            onClicked:              updateValues()
                        }
                    }
                }
            }
        }
    }

    GridLayout {
        columns: 2

        property Fact _freq:        _activeVehicle.wqFreq

        QGCLabel {
            text:                   qsTr("Freq")
            visible:                true
        }
        FactComboBox {
            fact:                   parent._freq
            indexModel:             false
        }

        QGCButton {
            //anchors.left:               parent.left
            text:                       qsTr("Start")
            visible:                    true
            onClicked:                  activeVehicle.setParam(1, "WQ_FREQ", parent._freq.rawValue)
            enabled:                    activeVehicle
        }
        QGCButton {
            //anchors.right:              parent.right
            text:                       qsTr("Stop")
            visible:                    true
            onClicked:                  activeVehicle.setParam(1, "WQ_FREQ", -1)
            enabled:                    activeVehicle
        }

        QGCLabel {
            text:                   qsTr("Show")
            visible:                true
        }
        FactComboBox {
            fact:                   QGroundControl.settingsManager.appSettings.wqDataType
            indexModel:             false
        }
    }

    property var enabledPalette:    QGCPalette { colorGroupEnabled: true }

    GridLayout {
        columns: 3

        QGCLabel {
            text:                   qsTr("domain1")
            visible:                true
        }
        FactTextField {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
            fact:                   QGroundControl.settingsManager.appSettings.domain1
        }
        ClickableColor {
            //id: enabledColorPicker
            color: "#00e04b"
            //onColorSelected: enabledPalette = color
        }

        QGCLabel {
            text:                   qsTr("domain2")
            visible:                true
        }
        FactTextField {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
            fact:                   QGroundControl.settingsManager.appSettings.domain2
        }
        ClickableColor {
            //id: enabledColorPicker
            color: "#de8500"
            //onColorSelected: enabledPalette = color
        }

        QGCLabel {
            text:                   qsTr("domain3")
            visible:                true
        }
        FactTextField {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
            fact:                   QGroundControl.settingsManager.appSettings.domain3
        }
        ClickableColor {
            //id: enabledColorPicker
            color: "#536dff"
            //onColorSelected: enabledPalette = color
        }

        QGCLabel {
            text:                   qsTr("domain4")
            visible:                true
        }
        FactTextField {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
            fact:                   QGroundControl.settingsManager.appSettings.domain4
        }
        ClickableColor {
            //id: enabledColorPicker
            color: "#f85761"
            //onColorSelected: enabledPalette = color
        }

        QGCLabel {
            text:                   qsTr("domain5")
            visible:                true
        }
        FactTextField {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
            fact:                   QGroundControl.settingsManager.appSettings.domain5
        }
        ClickableColor {
            //id: enabledColorPicker
            color: "#e10f3f"
            //onColorSelected: enabledPalette = color
        }
    }
}
