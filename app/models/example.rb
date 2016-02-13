class Example < ActiveRecord::Base
  # Expect to be passed in a column of data (an array called fields) and sort it
  # Return a properly sorted array of fields
  def self.sort(fields)
    fields.sort # maybe it's that simple!
  end

  # Populate the column data for this field
  def self.field_for(legislators, _column)
    field = {}

    legislators.each do |legislator|
      field[legislator.bioguide_id] = value_related_to_this_column
    end

    field[:header] = 'COLUMN HEADER'
    field[:title] = 'MOUSEOVER TEXT'
    field[:type] = 'string' # or digit or currency
    field
  end

  # Called from rake sources:update
  #
  # Usual algorithm:
  #
  #     1. Grab the data if it's a dataset, put it into data/sourcename
  #     2. Parse the data (whether as files in data/sourcename or from an API)
  #     3. Store it into the local database
  #
  # Make sure to create an entry in sources.yml for the data source
  def self.update(_options = {})
    ['SUCCESS', 'Message on success']
  end
end
