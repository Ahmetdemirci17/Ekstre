class Category < ApplicationRecord
  has_many :transactions, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :color, presence: true
end
