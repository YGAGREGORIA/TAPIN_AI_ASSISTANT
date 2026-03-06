import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "card",
    "number",
    "progress",
    "row"
  ]

  connect() {
    this.animateCards()
    this.animateNumbers()
    this.animateProgressBars()
    this.animateRows()
  }

  animateCards() {
    this.cardTargets.forEach((card, index) => {

      card.style.opacity = 0
      card.style.transform = "translateY(20px)"

      setTimeout(() => {
        card.style.transition = "all 0.5s ease"
        card.style.opacity = 1
        card.style.transform = "translateY(0)"
      }, index * 120)

    })
  }

  animateNumbers() {

    this.numberTargets.forEach((el) => {

      const finalNumber = parseInt(el.innerText)

      if (isNaN(finalNumber)) return

      let current = 0
      const increment = Math.ceil(finalNumber / 30)

      const counter = setInterval(() => {

        current += increment

        if (current >= finalNumber) {
          el.innerText = finalNumber
          clearInterval(counter)
        } else {
          el.innerText = current
        }

      }, 25)

    })

  }

  animateProgressBars() {

    this.progressTargets.forEach((bar) => {

      const width = bar.dataset.progress

      bar.style.width = "0%"

      setTimeout(() => {
        bar.style.transition = "width 1s ease"
        bar.style.width = width + "%"
      }, 300)

    })

  }

  animateRows() {

    this.rowTargets.forEach((row, index) => {

      row.style.opacity = 0
      row.style.transform = "translateY(10px)"

      setTimeout(() => {
        row.style.transition = "all 0.4s ease"
        row.style.opacity = 1
        row.style.transform = "translateY(0)"
      }, index * 80)

    })

  }

}
