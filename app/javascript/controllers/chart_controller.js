import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    type: { type: String, default: "line" },
    data: Object,
    options: Object
  }

  connect() {
    this.initChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  initChart() {
    if (typeof Chart === "undefined") {
      setTimeout(() => this.initChart(), 50)
      return
    }

    const existing = Chart.getChart(this.element)
    if (existing) {
      existing.destroy()
    }

    const ctx = this.element.getContext("2d")
    const config = {
      type: this.typeValue,
      data: this.dataValue,
      options: this.optionsValue || {}
    }

    this.chart = new Chart(ctx, config)
  }
}
