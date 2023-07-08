// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Drag from './dragHook'

let Hooks = {}
Hooks.Drag = Drag

Hooks.FocusInput = {
  mounted() {
    this.el.focus()

    // Put cursor at the end of the text content
    this.el.setSelectionRange(-1, -1)

    this.el.addEventListener("keyup", e => {
      if (e.key == "Escape") {
        e.preventDefault()
        this.pushEventTo(e.target,"cancel-editing-track")
      }
    })
  }
}

Hooks.Pear = {
  mounted() {
    this.el.addEventListener("dragstart", e => {
      e.dataTransfer.effectAllowed = "move"

      const pearName = e.target.getAttribute("phx-value-pear-name")
      const currentLocation = e.target.getAttribute("phx-value-current-location")

      this.pushEvent("drag-pear", {"pear-name": pearName, "current-location": currentLocation})

      e.dataTransfer.setData("pear-name", pearName)
      e.dataTransfer.setData("current-location", currentLocation)
    })

    this.el.addEventListener("dragover", e => {
      e.preventDefault()
    })
  }
}

Hooks.Destination = {
  mounted() {
    this.el.addEventListener("dragenter", e => {
      e.target.classList.add("dragged-over")
    })

    this.el.addEventListener("dragleave", e => {
      e.target.classList.remove("dragged-over")
    })

    this.el.addEventListener("dragover", e => {
      e.preventDefault()
    })

    this.el.addEventListener("drop", e => {
      e.preventDefault()
      e.target.classList.remove("dragged-over")

      let from = event.dataTransfer.getData("current-location")
      let to = e.target.getAttribute("phx-value-destination")
      let pear = event.dataTransfer.getData("pear-name")

      console.debug({from, to, pear})

      this.pushEvent("move-pear", {from, to, pear})
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

