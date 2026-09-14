class Statement < ApplicationRecord
  has_many :transactions, dependent: :destroy

  enum :status, {
    uploaded: "uploaded",
    parsed: "parsed",
    categorized: "categorized",
    failed: "failed"
  }, default: :uploaded

  validates :source_filename, presence: true

  def total_spent
    transactions.where("amount < 0").sum(:amount).abs
  end

  def total_income
    transactions.where("amount > 0").sum(:amount)
  end

  def categorized_count
    transactions.where.not(category_id: nil).count
  end

  def uncategorized_count
    transactions.where(category_id: nil).count
  end

  def categorization_percentage
    return 0 if transactions.empty?
    ((categorized_count.to_f / transactions.count) * 100).round
  end
end
