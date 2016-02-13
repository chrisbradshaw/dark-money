class AddChamberToRollCalls < ActiveRecord::Migration
  def self.up
    add_column :roll_calls, :chamber, :string
  end

  def self.down
    remove_column :roll_calls, :chamber
  end
end
