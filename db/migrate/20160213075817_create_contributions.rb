class CreateContributions < ActiveRecord::Migration

  def self.up
    create_table :contributions do |t|
      t.string :bioguide_id, :crp_id, :industry, :cycle
      t.integer :amount
      t.timestamps
    end
    add_index :contributions, [:cycle, :bioguide_id]
    add_index :contributions, [:cycle, :industry]
  end
  
  def self.down
    drop_table :contributions
  end

end