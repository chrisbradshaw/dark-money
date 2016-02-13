class CreateVotes < ActiveRecord::Migration

  def self.up
    create_table :votes do |t|
      t.string :bioguide_id, :govtrack_id, :roll_call_identifier, :position
      t.integer :roll_call_id
    end
    
    add_index :votes, :roll_call_id
    add_index :votes, :roll_call_identifier
  end
  
  def self.down
    drop_table :votes
  end
  
end