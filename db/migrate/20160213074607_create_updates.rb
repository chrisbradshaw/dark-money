class CreateUpdates < ActiveRecord::Migration
  def self.up
    create_table :updates do |t|
      t.string :source_keyword, :status, :message
      t.timestamps
    end
    add_index :updates, [:source_keyword, :status]
  end

  def self.down
    drop_table :updates
  end
end
