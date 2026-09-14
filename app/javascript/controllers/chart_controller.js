import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "centerDisplay", "centerLabel", "centerValue", "centerBadge"]
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
    const options = Object.assign({}, this.optionsValue || {})

    // Doughnut halkanın ortasında büyüyen detay efekti
    if (this.typeValue === "doughnut" && this.hasCenterDisplayTarget) {
      this.defaultLabel = this.hasCenterLabelTarget ? this.centerLabelTarget.textContent.trim() : "Toplam Harcama"
      this.defaultValue = this.hasCenterValueTarget ? this.centerValueTarget.textContent.trim() : ""

      options.onHover = (event, activeElements) => {
        this.handleDoughnutHover(activeElements)
      }

      canvas.addEventListener("mouseleave", () => this.resetDoughnutCenter())
    }

    const config = {
      type: this.typeValue,
      data: this.dataValue,
      options: options
    }

    this.chart = new Chart(ctx, config)
  }

  handleDoughnutHover(activeElements) {
    if (!this.hasCenterDisplayTarget) return

    if (activeElements && activeElements.length > 0) {
      const index = activeElements[0].index
      const dataset = this.chart.data.datasets[0]
      const label = this.chart.data.labels[index]
      const value = dataset.data[index]
      const color = Array.isArray(dataset.backgroundColor) ? dataset.backgroundColor[index] : "#E05252"
      const total = dataset.data.reduce((sum, val) => sum + (Number(val) || 0), 0)
      const percent = total > 0 ? ((value / total) * 100).toFixed(1) : "0"

      const formatted = new Intl.NumberFormat("tr-TR", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(value) + " ₺"

      if (this.hasCenterLabelTarget) {
        this.centerLabelTarget.textContent = label
        this.centerLabelTarget.style.color = color
      }
      if (this.hasCenterValueTarget) {
        this.centerValueTarget.textContent = formatted
      }
      if (this.hasCenterBadgeTarget) {
        this.centerBadgeTarget.textContent = `%${percent}`
        this.centerBadgeTarget.style.backgroundColor = `${color}25`
        this.centerBadgeTarget.style.borderColor = `${color}60`
        this.centerBadgeTarget.style.color = color
        this.centerBadgeTarget.classList.remove("hidden")
      }

      // Ekranda büyüyen efekt (scale ve vurgu)
      this.centerDisplayTarget.classList.remove("scale-100")
      this.centerDisplayTarget.classList.add("scale-110")
    } else {
      this.resetDoughnutCenter()
    }
  }

  resetDoughnutCenter() {
    if (!this.hasCenterDisplayTarget) return

    if (this.hasCenterLabelTarget) {
      this.centerLabelTarget.textContent = this.defaultLabel || "Toplam Harcama"
      this.centerLabelTarget.style.color = ""
    }
    if (this.hasCenterValueTarget) {
      this.centerValueTarget.textContent = this.defaultValue || ""
    }
    if (this.hasCenterBadgeTarget) {
      this.centerBadgeTarget.classList.add("hidden")
    }

    this.centerDisplayTarget.classList.remove("scale-110")
    this.centerDisplayTarget.classList.add("scale-100")
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

