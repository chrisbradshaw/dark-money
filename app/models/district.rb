require 'fastercsv'

class District < ActiveRecord::Base
  def self.sort(fields)
    cols = %w(blacks whites hispanics asians american_indians males females median_age median_house_value median_rent median_household_income)
    fields.sort { |a, b| cols.index(a) <=> cols.index(b) }
  end

  def self.field_for(legislators, column)
    field = {}
    legislators.each do |legislator|
      leg_district = ['Senior Seat', 'Junior Seat'].include?(legislator.district) ? 'state' : legislator.district
      if district = District.find_by_state_and_district(legislator.state, leg_district)
        field[legislator.bioguide_id] = district.send(column)
      end
    end
    field[:type] = 'digit'
    field
  end

  def self.update(options = {})
    data_dir = 'data/census/2000'
    old_dir = Dir.pwd

    FileUtils.rm_rf data_dir if options[:download] && File.exist?(data_dir)

    if !File.exist?(data_dir)
      FileUtils.mkdir_p data_dir
      FileUtils.chdir data_dir
      download_census
      unzip_census
    else
      FileUtils.chdir data_dir
    end

    # constructed in format "AK" => "20" for "State AK is at row index 20"
    states = {}
    header = File.new 'states/sl1/sl040-in-sl010-usgeo.uf1'

    i = 0
    until header.eof?
      row = header.readline
      name = row[200..289].strip
      states[name] ||= i
      i += 1
    end
    puts "[US] Found #{states.size} states/regions..."

    puts '[US] Reading in states...'
    state_pages = self.state_pages

    states_to_get = options[:state] ? { options[:state] => state_codes[options[:state]] } : state_codes

    state_counts = {}
    states_to_get.keys.sort.each do |state|
      ##### per-district files #####

      # constructed in format "1" => "20" for "District 1 is at row index 20"
      districts = {}
      header = File.new "districts/sl1/#{state}/sl500-in-sl040-#{state.downcase}geo.h10"

      puts "[#{state}] Reading in pages..."
      district_pages = self.district_pages state

      i = 0
      until header.eof?
        row = header.readline
        name = row[200..289]
        if (district = district_for(name)) && districts[district].nil?
          districts[district] = i
        end
        i += 1
      end
      puts "[#{state}] Found #{districts.keys.size} districts..."

      # Loop through each region name, making a district for each congressional district
      district_count = 0
      districts.each do |name, i|
        puts "  [District #{name}] Parsing census data..."

        district = District.find_or_initialize_by_state_and_district state, name
        fill_district district, district_pages, i
        district.save!

        district_count += 1
      end

      state_counts[state] = district_count

      # ####TODO: Per-state files ######

      puts '  [Statewide] Parsing census data...'

      district = District.find_or_initialize_by_state_and_district state, 'state'
      fill_district district, state_pages, states[state_codes[state]]
      district.save!
    end

    ['SUCCESS', "Updated district data from 2000 Census for #{state_counts.size} states."]
  rescue ActiveRecord::RecordInvalid => e
    ['FAILED', e.record.errors]
  rescue => e
    ['FAILED', "#{e.class}: #{e.message}"]
  ensure
    FileUtils.chdir old_dir
  end

  private

  # corresponds to page 00002 of dataset SL1, page 00059 of dataset SL3, etc.
  def self.page_map
    {
      sl1: [2],
      sl3: [4, 6, 59, 60]
    }
  end

  def self.state_codes
    {
      'AL' => 'Alabama',
      'AK' => 'Alaska',
      'AZ' => 'Arizona',
      'AR' => 'Arkansas',
      'CA' => 'California',
      'CO' => 'Colorado',
      'CT' => 'Connecticut',
      'DE' => 'Delaware',
      'DC' => 'District of Columbia',
      'FL' => 'Florida',
      'GA' => 'Georgia',
      'HI' => 'Hawaii',
      'ID' => 'Idaho',
      'IL' => 'Illinois',
      'IN' => 'Indiana',
      'IA' => 'Iowa',
      'KS' => 'Kansas',
      'KY' => 'Kentucky',
      'LA' => 'Louisiana',
      'ME' => 'Maine',
      'MD' => 'Maryland',
      'MA' => 'Massachusetts',
      'MI' => 'Michigan',
      'MN' => 'Minnesota',
      'MS' => 'Mississippi',
      'MO' => 'Missouri',
      'MT' => 'Montana',
      'NE' => 'Nebraska',
      'NV' => 'Nevada',
      'NH' => 'New Hampshire',
      'NJ' => 'New Jersey',
      'NM' => 'New Mexico',
      'NY' => 'New York',
      'NC' => 'North Carolina',
      'ND' => 'North Dakota',
      'OH' => 'Ohio',
      'OK' => 'Oklahoma',
      'OR' => 'Oregon',
      'PA' => 'Pennsylvania',
      'PR' => 'Puerto Rico',
      'RI' => 'Rhode Island',
      'SC' => 'South Carolina',
      'SD' => 'South Dakota',
      'TN' => 'Tennessee',
      'TX' => 'Texas',
      'UT' => 'Utah',
      'VT' => 'Vermont',
      'VA' => 'Virginia',
      'WA' => 'Washington',
      'WV' => 'West Virginia',
      'WI' => 'Wisconsin',
      'WY' => 'Wyoming'
    }
  end

  def self.district_pages(state)
    pages = {}
    ext_map = { sl1: 'h10', sl3: 's10' }
    page_map.each do |set, page_numbers|
      pages[set] = {}
      page_numbers.each do |number|
        filename = "sl500-in-sl040-#{state.downcase}#{zero_prefix number}.#{ext_map[set]}"
        page = FasterCSV.read "districts/#{set}/#{state}/#{filename}"
        pages[set][number] = page
      end
    end
    pages
  end

  def self.state_pages
    pages = {}
    ext_map = { sl1: 'uf1', sl3: 'uf3' }
    page_map.each do |set, page_numbers|
      pages[set] = {}
      page_numbers.each do |number|
        filename = "sl040-in-sl010-us#{zero_prefix number}.#{ext_map[set]}"
        page = FasterCSV.read "states/#{set}/#{filename}"
        pages[set][number] = page
      end
    end
    pages
  end

  def self.fill_district(district, pages, row)
    population = pages[:sl1][2][row][86].to_i
    district.population = population

    district.blacks = percent pages[:sl1][2][row][105].to_f, population
    district.american_indians = percent pages[:sl1][2][row][106].to_f, population
    district.asians = percent pages[:sl1][2][row][107].to_f, population
    district.whites = percent pages[:sl1][2][row][104].to_f, population
    district.hispanics = percent pages[:sl1][2][row][125].to_f, population

    district.males = percent pages[:sl1][2][row][127].to_f, population
    district.females = percent pages[:sl1][2][row][151].to_f, population

    district.median_age = pages[:sl1][2][row][175]
    district.median_household_income = pages[:sl3][6][row][87]
    district.median_house_value = pages[:sl3][60][row][251]
    district.median_rent = pages[:sl3][59][row][202]
  end

  # turns a percent like 0.56789 into 56.8
  def self.percent(value, population)
    ((value / population) * 1000).round / 10.0
  end

  # Turns "59" into "00059", "6" into "00006", etc.
  def self.zero_prefix(n, z = 5)
    "#{'0' * (z - n.to_s.size)}#{n}"
  end

  def self.download_census
    system 'wget http://www2.census.gov/census_2000/datasets/Summary_File_Extracts/110_Congressional_Districts/110_CD_HundredPercent/United_States/sl500-in-sl010-us_h10.zip'
    system 'wget http://www2.census.gov/census_2000/datasets/Summary_File_Extracts/110_Congressional_Districts/110_CD_Sample/United_States/sl500-in-sl010-us_s10.zip'
    system 'wget http://www2.census.gov/census_2000/datasets/Summary_File_Extracts/Summary_File_1/United_States/sl040-in-sl010-us_uf1.zip'
    system 'wget http://www2.census.gov/census_2000/datasets/Summary_File_Extracts/Summary_File_3/United_States/sl040-in-sl010-us_uf3.zip'
  end

  def self.unzip_census
    # districtwide files

    FileUtils.rm_rf 'districts'
    FileUtils.mkdir 'districts'

    system 'unzip -o sl500-in-sl010-us_h10.zip -d districts/sl1'
    state_codes.keys.each do |state|
      zip_file = "districts/sl1/sl500-in-sl040-#{state.downcase}_h10.zip"
      system "unzip #{zip_file} -d districts/sl1/#{state}"
      FileUtils.rm zip_file
    end
    FileUtils.rm 'sl500-in-sl010-us_h10.zip'

    system 'unzip -o sl500-in-sl010-us_s10.zip -d districts/sl3'
    state_codes.keys.each do |state|
      zip_file = "districts/sl3/sl500-in-sl040-#{state.downcase}_s10.zip"
      system "unzip #{zip_file} -d districts/sl3/#{state}"
      FileUtils.rm zip_file
    end
    FileUtils.rm 'sl500-in-sl010-us_s10.zip'

    # statewide files

    FileUtils.rm_rf 'states'
    FileUtils.mkdir 'states'

    system 'unzip -o sl040-in-sl010-us_uf1.zip -d states/sl1'
    FileUtils.rm 'sl040-in-sl010-us_uf1.zip'
    system 'unzip -o sl040-in-sl010-us_uf3.zip -d states/sl3'
    FileUtils.rm 'sl040-in-sl010-us_uf3.zip'
  end

  def self.district_for(name)
    case name
    when /District \(at Large\)/
      '0'
    when /District (\d+)/
      Regexp.last_match(1)
    end
  end
end
