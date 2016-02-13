class CreateSourceContributions < ActiveRecord::Migration
  def self.up
    create_table :source_contributions do |t|
      t.string :cycle, :contributor, :crp_identifier, :industry_category, :amount, :contribution_type
      t.timestamps
    end
    add_index :source_contributions, :cycle
    add_index :source_contributions, :crp_identifier
    add_index :source_contributions, :industry_category
    add_index :source_contributions, :contribution_type
  end

  def self.down
    drop_table :source_contributions
  end
end
