class CreateCandidates < ActiveRecord::Migration
  def self.up
    create_table :candidates do |t|
      t.string :bioguide_id, :crp_id, :cycle
      t.timestamps
    end
    add_index :candidates, [:cycle, :bioguide_id]
  end

  def self.down
    drop_table :candidates
  end
end
