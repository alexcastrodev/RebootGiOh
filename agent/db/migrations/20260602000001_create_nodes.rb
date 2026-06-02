class CreateNodes < ActiveRecord::Migration[8.0]
  def change
    create_table :nodes do |t|
      t.string   :discord_user_id, null: false, limit: 32
      t.string   :name,            null: false, limit: 64
      t.string   :host,            null: false, limit: 255
      t.datetime :last_seen

      t.timestamps
    end

    add_index :nodes, [:discord_user_id, :name], unique: true
  end
end
