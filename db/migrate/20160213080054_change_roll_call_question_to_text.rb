class ChangeRollCallQuestionToText < ActiveRecord::Migration

  def self.up
    change_column :roll_calls, :question, :text
  end
  
  def self.down
    change_column :roll_calls, :question, :string
  end

end