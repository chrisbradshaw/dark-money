class AddIndicesToContributions < ActiveRecord::Migration

  def self.up

    add_index :contributions, :bioguide_id
    add_index :contributions, :crp_id
    add_index :contributions, :industry
    add_index :contributions, :cycle
    add_index :contributions, :amount
    
  end
  
  def self.down
    
    remove_index :contributions, :bioguide_id
    remove_index :contributions, :crp_id
    remove_index :contributions, :industry
    remove_index :contributions, :cycle
    remove_index :contributions, :amount

  end

end