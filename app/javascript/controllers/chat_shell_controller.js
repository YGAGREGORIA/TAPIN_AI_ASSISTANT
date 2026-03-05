import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "sendBtn", "typing", "suggestions", "welcome", "overlay", "sidebar"]
  static values = { chatId: Number }

  connect() {
    this.scrollToBottom()
  }

  // Send message from form submit
  async send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (message === "") return

    this.appendUserMessage(message)
    this.inputTarget.value = ""
    this.showTyping()
    this.disableInput()
    this.hideWelcome()

    await this.postMessage(message)
  }

  // Send message from suggestion chip click
  async sendSuggestion(event) {
    event.preventDefault()

    const message = event.currentTarget.dataset.message
    if (!message) return

    this.appendUserMessage(message)
    this.showTyping()
    this.disableInput()
    this.hideWelcome()

    await this.postMessage(message)
  }

  // POST message to server and handle response
  async postMessage(message) {
    try {
      const response = await fetch(`/chats/${this.chatIdValue}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ message: message })
      })

      if (!response.ok) throw new Error("Request failed")

      const data = await response.json()
      this.hideTyping()
      this.appendAssistantMessage(data.assistant)
    } catch (error) {
      this.hideTyping()
      this.appendAssistantMessage("Sorry, something went wrong. Please try again.")
    } finally {
      this.enableInput()
    }
  }

  // DOM helpers
  appendUserMessage(text) {
    const html = `
      <div class="d-flex justify-content-end align-items-end gap-2 mb-3">
        <div class="chat-bubble chat-bubble-user">${this.escapeHtml(text)}</div>
        <div class="chat-avatar chat-avatar-user">You</div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  appendAssistantMessage(text) {
    const html = `
      <div class="d-flex justify-content-start align-items-end gap-2 mb-3">
        <div class="chat-avatar chat-avatar-ai">AI</div>
        <div class="chat-bubble chat-bubble-assistant">${this.escapeHtml(text)}</div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  showTyping() {
    if (this.hasTypingTarget) {
      this.typingTarget.classList.remove("d-none")
      this.scrollToBottom()
    }
  }

  hideTyping() {
    if (this.hasTypingTarget) {
      this.typingTarget.classList.add("d-none")
    }
  }

  hideWelcome() {
    if (this.hasWelcomeTarget) {
      this.welcomeTarget.remove()
    }
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.remove()
    }
  }

  disableInput() {
    this.inputTarget.disabled = true
    if (this.hasSendBtnTarget) {
      this.sendBtnTarget.disabled = true
    }
  }

  enableInput() {
    this.inputTarget.disabled = false
    if (this.hasSendBtnTarget) {
      this.sendBtnTarget.disabled = false
    }
    this.inputTarget.focus()
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    })
  }

  // Sidebar
  openSidebar() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.add("chat-sidebar-open")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("d-none")
    }
  }

  closeSidebar() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.remove("chat-sidebar-open")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("d-none")
    }
  }

  // Sanitize user input before DOM insertion
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
