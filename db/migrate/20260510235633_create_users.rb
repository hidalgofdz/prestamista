class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :string, limit: 25 do |t|
      t.references :account, null: false, type: :string, limit: 25
      t.string :email, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
