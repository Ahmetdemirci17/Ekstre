class CreateStatements < ActiveRecord::Migration[8.1]
  def change
    create_table :statements do |t|
      t.string :source_filename, null: false
      t.datetime :imported_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.string :bank_name
      t.string :status, default: "uploaded", null: false

      t.timestamps
    end
  end
end
