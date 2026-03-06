import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "messages",
    "input",
    "sendBtn",
    "suggestions",
    "welcome",
    "overlay",
    "sidebar",
    "chatTitle",
    "fileInput",
    "fileName",
    "filePreview"
  ]

  static values = { chatId: Number }

connect() {
  this.scrollToBottom()

  if (this.hasFileInputTarget) {
    this.fileInputTarget.addEventListener("change", () => {
      if (!this.hasFilePreviewTarget) return

      const file = this.fileInputTarget.files[0]
      this.filePreviewTarget.innerHTML = file
        ? `<div class="small text-muted mt-1"><i class="fas fa-paperclip me-1"></i>${this.escapeHtml(file.name)}</div>`
        : ""
    })
  }
}

  bindFilePreview() {
    if (!this.hasFileInputTarget) return

    this.fileInputTarget.addEventListener("change", () => {
      if (!this.hasFileNameTarget) return

      const file = this.fileInputTarget.files[0]
      this.fileNameTarget.textContent = file ? file.name : ""
    })
  }

  // Send message from form submit
  async send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    const file = this.hasFileInputTarget ? this.fileInputTarget.files[0] : null

    if (message === "" && !file) return

    this.appendUserMessage(message, file)
    this.inputTarget.value = ""
    if (this.hasFileInputTarget) this.fileInputTarget.value = ""
    if (this.hasFilePreviewTarget) this.filePreviewTarget.innerHTML = ""
    if (this.hasFileNameTarget) this.fileNameTarget.textContent = ""

    this.appendTyping()
    this.disableInput()
    this.hideWelcome()

    await this.postMessage(message, file)
  }

  // Send message from suggestion chip click
  async sendSuggestion(event) {
    event.preventDefault()

    const message = event.currentTarget.dataset.message
    if (!message) return

    this.appendUserMessage(message, null)
    this.appendTyping()
    this.disableInput()
    this.hideWelcome()

    await this.postMessage(message, null)
  }

  // POST message to server and handle response
  async postMessage(message, file = null) {
    try {
      const formData = new FormData()
      formData.append("message", message || "")
      if (file) formData.append("file", file)

      const response = await fetch(`/chats/${this.chatIdValue}/messages`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept": "application/json"
        },
        body: formData
      })

      if (!response.ok) throw new Error("Request failed")

      const data = await response.json()
      this.removeTyping()
      this.appendAssistantMessage(data.assistant)

      if (data.title && this.hasChatTitleTarget) {
        this.chatTitleTarget.textContent = data.title
      }
    } catch (error) {
      this.removeTyping()
      this.appendAssistantMessage("Sorry, something went wrong. Please try again.")
    } finally {
      this.enableInput()
    }
  }

  // DOM helpers
  appendUserMessage(text, file = null) {
    let body = ""

    if (text && file) {
      body = `
        <div>${this.escapeHtml(text)}</div>
        <div class="small mt-1 opacity-75">
          <i class="fas fa-paperclip me-1"></i>${this.escapeHtml(file.name)}
        </div>
      `
    } else if (text) {
      body = `<div>${this.escapeHtml(text)}</div>`
    } else if (file) {
      body = `
        <div>
          <i class="fas fa-paperclip me-1"></i>${this.escapeHtml(file.name)}
        </div>
      `
    }

    const html = `
      <div class="d-flex justify-content-end align-items-end gap-2 mb-3">
        <div class="chat-bubble chat-bubble-user">${body}</div>
        <div class="chat-avatar chat-avatar-user">You</div>
      </div>`

    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  appendAssistantMessage(text) {
    const formatted = this.escapeHtml(text).replace(/\n/g, "<br>")
    const html = `
      <div class="d-flex justify-content-start align-items-end gap-2 mb-3">
        <div class="chat-avatar chat-avatar-ai">AI</div>
        <div class="chat-bubble chat-bubble-assistant">${formatted}</div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  appendTyping() {
    const html = `
      <div class="d-flex align-items-end gap-2 mb-3" id="typing-indicator">
        <div class="chat-avatar chat-avatar-ai">AI</div>
        <div class="typing-indicator">
          <span class="dot"></span>
          <span class="dot"></span>
          <span class="dot"></span>
        </div>
      </div>`
    this.messagesTarget.insertAdjacentHTML("beforeend", html)
    this.scrollToBottom()
  }

  removeTyping() {
    const el = document.getElementById("typing-indicator")
    if (el) el.remove()
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
    if (this.hasFileInputTarget) this.fileInputTarget.disabled = true
    if (this.hasSendBtnTarget) {
      this.sendBtnTarget.disabled = true
    }
  }

  enableInput() {
    this.inputTarget.disabled = false
    if (this.hasFileInputTarget) this.fileInputTarget.disabled = false
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
