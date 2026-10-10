import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "vin3.headset-battery"

  // [{ name, percent, detail? } | { name, error }], one per headset that is
  // on right now; the widget hides itself when the list is empty.
  property var headsets: []
  readonly property string scriptPath:
    decodeURIComponent(String(Qt.resolvedUrl("headset-battery.py")).replace(/^file:\/\//, ""))

  function label(h) {
    return h.error ? "󰋋 !" : "󰋋 " + h.percent + "%"
  }

  function line(h) {
    if (h.error) return h.name + ": " + h.error
    return h.name + ": " + h.percent + "%" + (h.detail ? " (" + h.detail + ")" : "")
  }

  Process {
    id: readProc
    command: ["python3", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.headsets = JSON.parse(String(text || "").trim() || "[]")
        } catch (e) {
          root.headsets = []
        }
      }
    }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!readProc.running) readProc.running = true
  }

  visible: headsets.length > 0
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.headsets.map(root.label).join("  ")
    active: root.headsets.some(function (h) { return !h.error && h.percent <= 15 })
    tooltipText: root.headsets.map(root.line).join("\n")
    onPressed: function (btn) { if (!readProc.running) readProc.running = true }
  }
}
