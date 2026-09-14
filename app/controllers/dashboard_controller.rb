class DashboardController < ApplicationController
  def index
    # Use latest transaction date as anchor, or current date if empty
    latest_date = Transaction.maximum(:date) || Date.current
    @target_date = params[:date].present? ? Date.parse(params[:date]) : latest_date

    @current_month_start = @target_date.beginning_of_month
    @current_month_end = @target_date.end_of_month
    @prev_month_start = (@target_date - 1.month).beginning_of_month
    @prev_month_end = (@target_date - 1.month).end_of_month

    # Current month KPI metrics
    current_month_txs = Transaction.where(date: @current_month_start..@current_month_end)
    @this_month_spent = current_month_txs.expenses.sum(:amount).abs
    @this_month_income = current_month_txs.incomes.sum(:amount)
    @this_month_count = current_month_txs.count

    # Previous month comparison
    prev_month_txs = Transaction.where(date: @prev_month_start..@prev_month_end)
    @prev_month_spent = prev_month_txs.expenses.sum(:amount).abs

    @mom_change = if @prev_month_spent > 0
                    (((@this_month_spent - @prev_month_spent) / @prev_month_spent) * 100).round(1)
                  else
                    nil
                  end

    # Top spending category
    top_cat_record = current_month_txs.expenses
                                       .joins(:category)
                                       .group("categories.name", "categories.color")
                                       .select("categories.name, categories.color, SUM(ABS(transactions.amount)) as total")
                                       .order("total DESC")
                                       .first

    @top_category_name = top_cat_record&.name || "Veri yok"
    @top_category_amount = top_cat_record&.total || 0
    @top_category_color = top_cat_record&.color || "#6B7280"

    # 1. Line Chart: 6 Months Trend
    months = (0..5).to_a.reverse.map { |i| (@target_date - i.months).beginning_of_month }
    month_names_tr = {
      1 => "Oca", 2 => "Şub", 3 => "Mar", 4 => "Nis", 5 => "May", 6 => "Haz",
      7 => "Tem", 8 => "Ağu", 9 => "Eyl", 10 => "Eki", 11 => "Kas", 12 => "Ara"
    }

    trend_labels = []
    expense_data = []
    income_data = []

    months.each do |m|
      m_start = m.beginning_of_month
      m_end = m.end_of_month
      trend_labels << "#{month_names_tr[m.month]} #{m.year}"
      expense_data << Transaction.where(date: m_start..m_end).expenses.sum(:amount).abs.to_f
      income_data << Transaction.where(date: m_start..m_end).incomes.sum(:amount).to_f
    end

    @trend_chart_data = {
      labels: trend_labels,
      datasets: [
        {
          label: "Harcamalar (Gider)",
          data: expense_data,
          borderColor: "#B91C1C",
          backgroundColor: "rgba(185, 28, 28, 0.08)",
          borderWidth: 2,
          tension: 0.25,
          fill: true,
          pointBackgroundColor: "#B91C1C",
          pointBorderColor: "#18191E",
          pointBorderWidth: 1.5,
          pointRadius: 3.5
        },
        {
          label: "Gelirler",
          data: income_data,
          borderColor: "#059669",
          backgroundColor: "rgba(5, 150, 105, 0.08)",
          borderWidth: 2,
          tension: 0.25,
          fill: true,
          pointBackgroundColor: "#059669",
          pointBorderColor: "#18191E",
          pointBorderWidth: 1.5,
          pointRadius: 3.5
        }
      ]
    }

    # 2. Doughnut Chart: Category Distribution for Current Month
    category_grouped = current_month_txs.expenses
                                        .left_joins(:category)
                                        .group("COALESCE(categories.name, 'Kategorisiz')", "COALESCE(categories.color, '#64748B')")
                                        .sum("ABS(transactions.amount)")

    cat_labels = []
    cat_values = []
    cat_colors = []

    category_grouped.each do |(name, color), total|
      cat_labels << name
      cat_values << total.to_f
      cat_colors << color
    end

    @category_chart_data = {
      labels: cat_labels,
      datasets: [
        {
          data: cat_values,
          backgroundColor: cat_colors,
          borderColor: "#18191E",
          borderWidth: 2,
          hoverOffset: 20,
          hoverBorderColor: "#ECEEF2",
          hoverBorderWidth: 2
        }
      ]
    }

    # Recent Transactions
    @recent_transactions = Transaction.includes(:category, :statement)
                                      .order(date: :desc, id: :desc)
                                      .limit(8)

    # Statements summary
    @total_statements = Statement.count
  end
end
