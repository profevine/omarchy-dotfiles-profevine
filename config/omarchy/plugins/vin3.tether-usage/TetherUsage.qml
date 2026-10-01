import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "vin3.tether-usage"

  // The kernel counters start at zero when the phone's interface appears and
  // vanish with it, so a session is exactly the life of that interface: an
  // unplug or a tethering toggle on the phone starts the next one from zero.
  property bool tethered: false
  property real rxBytes: 0
  property real txBytes: 0
  readonly property real totalBytes: rxBytes + txBytes

  function gb(bytes) {
    return (bytes / 1e9).toFixed(2) + " GB"
  }

  // Phones tether over RNDIS (Android), NCM/ECM (newer Android) or ipheth
  // (iPhone). Picking by driver rather than by name survives the interface
  // being renamed when the cable goes into another port.
  Process {
    id: readProc
    command: ["sh", "-c",
      "for d in /sys/class/net/*; do " +
      "  drv=$(basename \"$(readlink \"$d/device/driver\" 2>/dev/null)\"); " +
      "  case \"$drv\" in rndis_host|cdc_ncm|cdc_ether|ipheth) " +
      "    echo \"$(cat \"$d/statistics/rx_bytes\") $(cat \"$d/statistics/tx_bytes\")\";; esac; " +
      "done"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        let rx = 0, tx = 0, found = false
        String(text || "").trim().split("\n").forEach(function (line) {
          const f = line.trim().split(/\s+/)
          if (f.length !== 2) return
          rx += Number(f[0]) || 0
          tx += Number(f[1]) || 0
          found = true
        })
        root.tethered = found
        root.rxBytes = rx
        root.txBytes = tx
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!readProc.running) readProc.running = true
  }

  visible: tethered
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf10b " + root.gb(root.totalBytes)
    tooltipText: "Tethering USB\n↓ " + root.gb(root.rxBytes) + "   ↑ " + root.gb(root.txBytes)
  }
}
