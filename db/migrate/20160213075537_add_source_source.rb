class AddSourceSource < ActiveRecord::Migration

  def self.up
    add_column :sources, :source_name, :string
    add_column :sources, :source_url, :string
  end
  
  def self.down
    remove_column :sources, :source_url
    remove_column :sources, :source_name
  end

end