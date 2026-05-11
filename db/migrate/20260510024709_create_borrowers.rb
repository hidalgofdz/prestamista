class CreateBorrowers < ActiveRecord::Migration[8.1]
  def change
    create_table :borrowers, id: :string, limit: 25 do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.references :account, null: false, type: :string, limit: 25

      t.timestamps
    end
  end
end
