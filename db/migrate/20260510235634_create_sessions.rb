class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :string, limit: 25 do |t|
      t.references :user, null: false, type: :string, limit: 25
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
