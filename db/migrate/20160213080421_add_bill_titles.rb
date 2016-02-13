class AddBillTitles < ActiveRecord::Migration
  def self.up
    add_column :roll_calls, :bill_title, :string
  end

  def self.down
    remove_column :roll_calls, :bill_title
  end
end
