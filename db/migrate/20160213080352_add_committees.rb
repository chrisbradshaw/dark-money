class AddCommittees < ActiveRecord::Migration
  def self.up
    create_table :committees do |t|
      t.string :chamber, :keyword, :name
      t.integer :parent_id
    end
    add_index :committees, :parent_id

    create_table :committee_memberships do |t|
      t.integer :legislator_id, :committee_id
    end
    add_index :committee_memberships, [:legislator_id, :committee_id]
    add_index :committee_memberships, :committee_id

    add_index :committees, :keyword
    add_index :committees, :chamber
  end

  def self.down
    drop_table :committee_memberships
    drop_table :committees
  end
end
