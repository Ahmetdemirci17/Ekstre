class CategorizeTransactionsJob < ApplicationJob
  queue_as :default

  def perform(statement_id)
    statement = Statement.find_by(id: statement_id)
    return unless statement

    uncategorized_txs = statement.transactions.uncategorized.to_a
    return if uncategorized_txs.empty?

    default_category = Category.find_by(name: "Diğer") || Category.first

    uncategorized_txs.each_slice(20) do |batch|
      categorizer = GeminiCategorizer.new(batch)
      result = categorizer.call

      next unless result[:success] && result[:results].present?

      result[:results].each do |tx_id, category_name|
        transaction = batch.find { |t| t.id == tx_id }
        next unless transaction

        detail = result[:details]&.dig(tx_id) || {}
        cat_clean = category_name.to_s.strip
        matched_category = Category.where("LOWER(name) = ?", cat_clean.downcase).first || default_category

        transaction.update(
          category: matched_category,
          merchant_name: detail[:merchant].presence || transaction.merchant_name,
          ai_analysis: detail[:analysis].presence || transaction.ai_analysis,
          confidence_score: detail[:confidence] || transaction.confidence_score,
          categorized_by: :ai
        )
      end
    end

    statement.update(status: :categorized) if statement.transactions.uncategorized.none?
  end
end
