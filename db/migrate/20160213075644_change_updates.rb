class ChangeUpdates < ActiveRecord::Migration
  def self.up
    remove_index :updates, [:source_keyword, :status]
    rename_column :updates, :source_keyword, :source
    add_index :updates, [:source, :status]

    change_column :updates, :message, :text

    add_column :updates, :elapsed_time, :integer
  end

  def self.down
    remove_column :updates, :elapsed_time

    change_column :updates, :message, :string

    remove_index :updates, [:source, :status]
    rename_column :updates, :source, :source_keyword
    add_index :updates, [:source_keyword, :status]
  end
end
