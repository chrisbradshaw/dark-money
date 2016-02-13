class AddMoreLegislatorIds < ActiveRecord::Migration
  def self.up
    add_column :legislators, :crp_id, :string
    add_column :legislators, :votesmart_id, :string
    add_column :legislators, :fec_id, :string
    add_column :legislators, :govtrack_id, :string
  end

  def self.down
    remove_column :legislators, :govtrack_id
    remove_column :legislators, :fec_id
    remove_column :legislators, :votesmart_id
    remove_column :legislators, :crp_id
  end
end
