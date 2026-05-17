import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chip", "row"]

  filter(event) {
    const chip = event.currentTarget
    const wasPressed = chip.getAttribute("aria-pressed") === "true"

    this.chipTargets.forEach(c => c.setAttribute("aria-pressed", "false"))

    if (wasPressed) {
      this.rowTargets.forEach(row => row.hidden = false)
    } else {
      chip.setAttribute("aria-pressed", "true")
      const group = chip.dataset.filter
      this.rowTargets.forEach(row => {
        row.hidden = row.dataset.filterGroup !== group
      })
    }
  }
}
