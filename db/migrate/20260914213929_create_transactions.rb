class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :statement, null: false, foreign_key: true
      t.references :category, null: true, foreign_key: true
      t.date :date, null: false
      t.text :description, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :raw_row
      t.integer :categorized_by, default: 0, null: false

      t.timestamps
    end
    add_index :transactions, :date
  end
end
