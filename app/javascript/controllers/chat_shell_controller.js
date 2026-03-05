import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

static targets = ["messages","input"]
static values = { chatId: Number }

async send(event){

event.preventDefault()

const message = this.inputTarget.value

if(message.trim() === "") return

const chatId = this.chatIdValue

this.messagesTarget.insertAdjacentHTML(
"beforeend",
`<div class="d-flex justify-content-end mb-2">
<div class="bg-primary text-white rounded-4 px-3 py-2">
${message}
</div></div>`
)

this.inputTarget.value=""

const response = await fetch(`/chats/${chatId}/messages`,{

method:"POST",

headers:{
"Content-Type":"application/json",
"X-CSRF-Token":document.querySelector("meta[name='csrf-token']").content
},

body:JSON.stringify({message:message})

})

const data = await response.json()

this.messagesTarget.insertAdjacentHTML(
"beforeend",
`<div class="d-flex justify-content-start mb-2">
<div class="bg-white border rounded-4 px-3 py-2">
${data.assistant}
</div></div>`
)

this.messagesTarget.scrollTop=this.messagesTarget.scrollHeight

}

}
