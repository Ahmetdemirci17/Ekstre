class Transaction < ApplicationRecord
  belongs_to :statement
  belongs_to :category, optional: true

  enum :categorized_by, {
    unassigned: 0,
    manual: 1,
    ai: 2
  }, default: :unassigned

  validates :date, presence: true
  validates :description, presence: true
  validates :amount, presence: true, numericality: true

  scope :chronological, -> { order(date: :desc, id: :desc) }
  scope :uncategorized, -> { where(category_id: nil) }
  scope :categorized, -> { where.not(category_id: nil) }
  scope :expenses, -> { where("amount < 0") }
  scope :incomes, -> { where("amount > 0") }

  def expense?
    amount.present? && amount.negative?
  end

  def income?
    amount.present? && amount.positive?
  end

  def formatted_amount
    sprintf("%.2f TL", amount.abs)
  end

  def categorized_by_ai?
    ai?
  end
end
