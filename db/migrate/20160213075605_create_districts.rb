class CreateDistricts < ActiveRecord::Migration

  def self.up
    create_table :districts do |t|
      t.string :state, :district
      t.integer :population
      
      t.float :males, :females,
        :blacks, :american_indians, :asians, :whites, :hispanics,
        :median_age, :median_household_income, 
        :median_house_value, :median_rent
        # Other field ideas for the future
        # These are more complicated to parse now
        # :arabs, :english, :germans, :french, :irish, :russians, :americans, 
        # :high_school, :bachelors,
    end
    
    add_index :districts, [:state, :district]
  end
  
  def self.down
    drop_table :districts
  end
  
endˇ