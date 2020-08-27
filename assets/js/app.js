// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let Hooks = {}
Hooks.FocusInput = {
  mounted(){
    this.el.focus()

    // Put cursor at the end of the text content
    this.el.setSelectionRange(-1, -1)
  }
}

Hooks.Pear = {
  mounted(){
    this.el.addEventListener("dragstart", e => {
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("from-track", e.target.dataset.trackName)
      e.dataTransfer.setData("pear-name", e.target.dataset.pearName)
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

      let from = event.dataTransfer.getData("from-track") || "Unassigned"
      let to = e.target.dataset.trackName || "Unassigned"
      let pear = event.dataTransfer.getData("pear-name")

      console.debug({from, to, pear})

      this.pushEvent("move-pear", {from, to, pear})
    })
  }
}


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
