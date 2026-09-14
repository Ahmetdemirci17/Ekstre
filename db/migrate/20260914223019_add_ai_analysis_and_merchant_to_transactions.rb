class AddAiAnalysisAndMerchantToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :merchant_name, :string
    add_column :transactions, :ai_analysis, :text
    add_column :transactions, :confidence_score, :decimal, precision: 3, scale: 2
  end
end
