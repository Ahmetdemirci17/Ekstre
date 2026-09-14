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
          label: "Harcamalar",
          data: expense_data,
          borderColor: "#F43F5E",
          backgroundColor: "rgba(244, 63, 94, 0.15)",
          borderWidth: 2.5,
          tension: 0.35,
          fill: true,
          pointBackgroundColor: "#F43F5E",
          pointRadius: 4
        },
        {
          label: "Gelirler",
          data: income_data,
          borderColor: "#10B981",
          backgroundColor: "rgba(16, 185, 129, 0.15)",
          borderWidth: 2.5,
          tension: 0.35,
          fill: true,
          pointBackgroundColor: "#10B981",
          pointRadius: 4
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
          borderColor: "#0F172A",
          borderWidth: 2
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
