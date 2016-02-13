class AddMoreColumnsToLegislators < ActiveRecord::Migration

  def self.up
    add_column :legislators, :phone, :string
    add_column :legislators, :website, :string
    add_column :legislators, :twitter_id, :string
    add_column :legislators, :youtube_url, :string
    add_column :legislators, :birthdate, :timestamp
  end
  
  def self.down
    remove_column :legislators, :youtube_url, :twitter_id, :website, :phone, :birthdate
    remove_column :legislators, :birthdate
  end

end