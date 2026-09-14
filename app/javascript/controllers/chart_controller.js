import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]
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

    const canvas = this.hasCanvasTarget ? this.canvasTarget : this.element
    const existing = Chart.getChart(canvas)
    if (existing) {
      existing.destroy()
    }

    const ctx = canvas.getContext("2d")
    const config = {
      type: this.typeValue,
      data: this.dataValue,
      options: this.optionsValue || {}
    }

    this.chart = new Chart(ctx, config)
  }

  toggleDataset(event) {
    const button = event.currentTarget
    const datasetIndex = parseInt(event.params?.datasetIndex ?? button.dataset.chartDatasetIndexParam)
    if (!this.chart || isNaN(datasetIndex)) return

    const isVisible = this.chart.isDatasetVisible(datasetIndex)
    const newVisible = !isVisible

    this.chart.setDatasetVisibility(datasetIndex, newVisible)
    this.chart.update()

    this.updateButtonUI(button, newVisible)
  }

  updateButtonUI(button, isVisible) {
    const box = button.querySelector(".legend-box")
    const svg = button.querySelector(".legend-check")
    const label = button.querySelector(".legend-label")
    const color = button.dataset.chartColor

    if (isVisible) {
      // Açık / Görünür: Kutucuğun içi dolu, onay işareti aktif
      button.classList.remove("opacity-40")
      button.classList.add("opacity-100")
      button.setAttribute("aria-pressed", "true")
      button.title = "Grafikte gösteriliyor (Gizlemek için tıklayın)"

      if (box) {
        box.style.backgroundColor = color
        box.style.borderColor = color
      }
      if (svg) {
        svg.classList.remove("opacity-0")
        svg.classList.add("opacity-100")
      }
      if (label) {
        label.classList.remove("text-zinc-500", "line-through")
        label.classList.add("text-zinc-200")
      }
    } else {
      // Kapalı / Gizli: Kutucuğun içi boş, onay işareti gizli
      button.classList.remove("opacity-100")
      button.classList.add("opacity-40")
      button.setAttribute("aria-pressed", "false")
      button.title = "Grafikte gizlendi (Göstermek için tıklayın)"

      if (box) {
        box.style.backgroundColor = "transparent"
        box.style.borderColor = "#52525B" // zinc-600
      }
      if (svg) {
        svg.classList.remove("opacity-100")
        svg.classList.add("opacity-0")
      }
      if (label) {
        label.classList.remove("text-zinc-200")
        label.classList.add("text-zinc-500", "line-through")
      }
    }
  }
}

