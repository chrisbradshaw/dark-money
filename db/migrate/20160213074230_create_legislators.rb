class CreateLegislators < ActiveRecord::Migration
  def self.up
    create_table :legislators do |t|
      t.string :chamber, :name, :gender, :district, :state, :party, :bioguide_id
      t.boolean :in_office
      t.timestamps
    end
    add_index :legislators, [:state, :district]
    add_index :legislators, :bioguide_id
  end

  def self.down
    drop_table :legislators
  end
end
