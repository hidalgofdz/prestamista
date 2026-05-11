class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments, id: :string, limit: 25 do |t|
      t.references :account, null: false, type: :string, limit: 25
      t.references :loan, null: false, type: :string, limit: 25
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :date, null: false
      t.decimal :interest_applied, precision: 12, scale: 2, null: false
      t.decimal :principal_applied, precision: 12, scale: 2, null: false

      t.timestamps
    end
  end
end
