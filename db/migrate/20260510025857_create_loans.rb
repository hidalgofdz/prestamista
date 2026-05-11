class CreateLoans < ActiveRecord::Migration[8.1]
  def change
    create_table :loans, id: :string, limit: 25 do |t|
      t.references :account, null: false, type: :string, limit: 25
      t.references :borrower, null: false, type: :string, limit: 25
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :annual_interest_rate, precision: 5, scale: 2, null: false
      t.integer :term_months, null: false
      t.date :start_date, null: false

      t.timestamps
    end
  end
end
