import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "messages", "input", "search", "list"]
  static values = { conversationId: Number }

  openSidebar() {
    this.overlayTarget.hidden = false
    this.sidebarTarget.style.transform = "translateX(0)"
  }

  closeSidebar() {
    this.overlayTarget.hidden = true
    this.sidebarTarget.style.transform = "translateX(-100%)"
  }

  async send(event) {
    event.preventDefault()

    const text = (this.inputTarget.value || "").trim()
    if (!text) return

    this.appendMessage("user", text)
    this.inputTarget.value = ""

    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    const url = `/conversations/${this.conversationIdValue}/reply`

    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      body: JSON.stringify({ message: text })
    })

    if (!res.ok) {
      this.appendMessage("assistant", "Sorry, something went wrong.")
      return
    }

    const data = await res.json()
    this.appendMessage("assistant", data.assistant || "OK")
  }

  appendMessage(role, text) {
    const row = document.createElement("div")
    row.className = role === "user"
      ? "d-flex justify-content-end mb-2"
      : "d-flex justify-content-start mb-2"

    const bubble = document.createElement("div")
    bubble.className = role === "user"
      ? "bg-primary text-white rounded-4 px-3 py-2 shadow-sm"
      : "bg-white border rounded-4 px-3 py-2 shadow-sm"

    bubble.style.maxWidth = "85%"
    bubble.textContent = text

    row.appendChild(bubble)
    this.messagesTarget.appendChild(row)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
