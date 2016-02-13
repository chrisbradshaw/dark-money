require 'httparty'
require 'htmlentities'
require 'fastercsv'

class Contribution < ActiveRecord::Base
  validates_presence_of :cycle, :crp_id, :bioguide_id, :industry

  named_scope :cycle, lambda {|cycle|
    { conditions: { cycle: cycle } }
  }
  named_scope :industries, lambda {|industry|
    if !industry.blank? && industry != '*'
      { select: 'distinct industry', conditions: ['industry like ?', "%#{industry}%"] }
    else
      { select: 'distinct industry' }
    end
  }

  named_scope :legislator, lambda {|bioguide_id|
    { conditions: { bioguide_id: bioguide_id } }
  }

  def self.sort(fields)
    fields.sort
  end

  def self.field_for(legislators, column)
    field = {}
    cycle = latest_cycle

    if column == 'top_industries'
      legislators.each do |legislator|
        industries = Contribution.cycle(cycle).legislator(legislator.bioguide_id).industries(nil).all(order: 'amount desc', limit: 3)

        field[legislator.bioguide_id] = {
          html: industries.map do|contribution|
            %(<a href="#" class="filter" title="Filter by #{contribution.industry}">#{contribution.industry}</a>)
          end.join(', '),
          data: industries.map(&:industry).join(', ')
        }
      end
    else
      industry = column
      coder = HTMLEntities.new

      contribution_data = {}
      contributions = Contribution.find_all_by_cycle_and_industry cycle, industry
      if contributions.empty?
        contributions = Contribution.find_all_by_cycle_and_industry cycle, coder.encode(industry)
      end
      contributions.each { |contribution| contribution_data[contribution.bioguide_id] = format_amount(contribution.amount) }

      legislators.each do |legislator|
        field[legislator.bioguide_id] = contribution_data[legislator.bioguide_id]
      end

      field[:header] = "#{industry} (#{cycle})"
      field[:title] = "Contributions by #{industry} to this candidate in the #{cycle} election cycle."
      field[:type] = 'currency' # force table sorting as currency
    end

    field
  end

  def self.form_data
    { industries: Contribution.cycle(Contribution.latest_cycle).industries.all(order: 'industry asc').map(&:industry) }
  end

  # taken from http://codesnippets.joyent.com/posts/show/1812
  def self.format_amount(number, options = {})
    options = { currency_symbol: '$', delimiter: ',', decimal_symbol: '.', currency_before: true }.merge(options)

    int, frac = ('%.2f' % number).split('.')
    int.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")

    if options[:currency_before]
      options[:currency_symbol] + int + options[:decimal_symbol] + frac
    else
      int + options[:decimal_symbol] + frac + options[:currency_symbol]
    end
  end

  def self.update(options = {})
    cycle = options[:cycle] || latest_cycle.to_s[2..3]
    unless SourceContribution.source_files_present?(cycle)
      update_via_api(options)
      return
    end

    if SourceContribution.find(:all).empty?
      puts 'Loading CSV data (this will take a while)...'
      SourceContribution.load_for_cycle(cycle)
      puts 'Done loading CSV data...'
    end

    # category codes (also known as RealCodes) and their Industry
    get_industry_codes
    industry_codes = {}
    FasterCSV.foreach('data/opensecrets/IndustryCategories.txt', col_sep: "\t", headers: true) do |row|
      industry_codes[row['Catcode']] = row['Industry']
    end
    puts 'Done loading hash for industry categories...'

    # the industries we care about
    industries = industry_codes.values.uniq!
    ['No Employer Listed or Found', 'Non-contribution', 'Other', 'Unknown',
     'Employer Listed/Category Unknown', 'Generic Occupation/Category Unknown',
     'Party Committees', 'Misc Issues', 'Retired'].each do |to_delete|
      industries.delete(to_delete)
    end

    puts 'Aggregating industry amounts per Legislator...'
    Legislator.active.each do |legislator|
      puts "Aggregating for #{legislator.name}..."

      industry_aggregates = {}
      industries.each do |key|
        industry_aggregates[key] = 0.00
      end

      SourceContribution.find_all_by_crp_identifier(legislator.crp_id).each do |source_contribution|
        industry = industry_codes[source_contribution.industry_category]
        if industries.include?(industry)
          industry_aggregates[industry] += source_contribution.amount.to_f
        end
      end

      industry_aggregates.each do |industry, amount|
        next unless amount > 0.00
        contribution = Contribution.find_or_initialize_by_industry_and_cycle_and_bioguide_id industry, latest_cycle, legislator.bioguide_id
        contribution.crp_id = legislator.crp_id
        contribution.amount = amount
        contribution.save!
      end
    end

    ['SUCCESS', '']
  rescue => e
    ['FAILED', "#{e.class}: #{e.message}"]
  end

  def self.update_via_api(options = {})
    cycle = options[:cycle] || latest_cycle
    limit = options[:limit] || Legislator.count

    secrets = OpenSecrets.new api_key: api_key, cycle: cycle

    create_count = 0
    contribution_count = 0

    candidates = []
    mistakes = []

    # update the candidates table with any new legislator info
    # TODO: Improve the performance here, one single query
    Legislator.active.each do |legislator|
      candidate = Candidate.find_or_initialize_by_bioguide_id_and_crp_id_and_cycle(legislator.bioguide_id, legislator.crp_id, latest_cycle)

      next unless candidate.new_record?
      if candidate.valid?
        # toss any new legislators in the queue to get updated, up to the limit
        candidates << candidate if candidates.size < limit

        candidate.save!
        create_count += 1
      else
        mistakes << "Invalid candidate, Bioguide #{legislator.bioguide_id}, errors:\n\t #{candidate.errors.full_messages.join("\n\t")}"
      end
    end

    # any remaining slots should be filled in by the least recently updated legislators
    remaining = limit - candidates.size
    if remaining > 0
      candidates += Candidate.all order: 'updated_at asc', limit: remaining
    end

    # if there are few enough legislators, there may be duplicates from that process
    candidates = candidates.uniq

    candidate_count = 0
    # for each candidate, find or create the contribution row for each industry
    candidates.each do |candidate|
      industries = secrets.industries candidate.crp_id
      if industries.is_a? String
        mistakes << "Couldn't get industries for bioguide #{candidate.bioguide_id}, message: #{industries}"
      else
        puts "[#{candidate.bioguide_id}] Scanning top industries..."
        industries['response']['industries']['industry'].each do |industry|
          name = industry['industry_name']
          amount = industry['total']
          contribution = Contribution.find_or_initialize_by_industry_and_cycle_and_bioguide_id name, cycle, candidate.bioguide_id
          contribution.crp_id = candidate.crp_id
          contribution.amount = amount
          contribution.save!

          puts "\t#{name}: #{amount}"

          contribution_count += 1
        end

        # update updated_at
        candidate.update_attribute :updated_at, Time.now
        candidate_count += 1
      end
    end

    puts "\n#{mistakes.join("\n")}" if mistakes.any?

    ['SUCCESS', "Success, created #{create_count} new candidate rows, updated #{candidate_count} candidates with #{contribution_count} rows of industry contributions"]
  rescue => e
    ['FAILED', "#{e.class}: #{e.message}"]
  end

  # 2008 => 2008, 2009 => 2008, 2010 => 2010
  # This relies on truncating integers
  def self.latest_cycle
    Time.now.year / 2 * 2
  end

  def self.get_industry_codes
    FileUtils.mkdir_p 'data/opensecrets'
    system 'curl http://www.opensecrets.org/downloads/crp/CRP_Categories.txt > data/opensecrets/IndustryCategories.txt.tmp'
    # clean it up
    tmp_file = File.open('data/opensecrets/IndustryCategories.txt.tmp', 'r+')
    file = File.new('data/opensecrets/IndustryCategories.txt', 'w')
    at_content = false
    tmp_file.each_line do |line|
      at_content = true if line =~ /Catcode*/
      file.puts line if at_content
    end
    system 'rm data/opensecrets/IndustryCategories.txt.tmp'
  end
end

class OpenSecrets
  include HTTParty
  base_uri 'http://www.opensecrets.org/api'
  attr_accessor :api_key, :cycle

  def initialize(options = {})
    self.api_key = options[:api_key]
    self.cycle = options[:cycle]
  end

  def industries(crp_id, url_options = {})
    self.class.get '/', query: url_options.merge(method: 'candIndustry', cid: crp_id, apikey: api_key, cycle: cycle)
  end
end

class SourceContribution < ActiveRecord::Base
  def self.source_files_present?(cycle)
    File.exist?("data/opensecrets/CampaignFin#{cycle}/indivs#{cycle}.csv") && File.exist?("data/opensecrets/CampaignFin#{cycle}/pacs#{cycle}.csv")
  end

  def self.load_for_cycle(cycle)
    active_crp_identifiers = []
    Legislator.active.each do |legislator|
      active_crp_identifiers << legislator.crp_id
    end

    File.foreach("data/opensecrets/CampaignFin#{cycle}/indivs#{cycle}.csv") do |raw_row|
      begin
        row = FasterCSV.parse_line(raw_row)
        SourceContribution.create(cycle: row[0], contributor: row[3], crp_identifier: row[4],
                                  industry_category: row[7], amount: row[9],
                                  contribution_type: 'individual') if active_crp_identifiers.include?(row[4])
      rescue FasterCSV::MalformedCSVError
        puts 'skipping line: ' + $ERROR_INFO
      end
    end

    File.foreach("data/opensecrets/CampaignFin#{cycle}/pacs#{cycle}.csv") do |raw_row|
      begin
        row = FasterCSV.parse_line(raw_row)
        SourceContribution.create(cycle: row[0], contributor: row[2], crp_identifier: row[3],
                                  industry_category: row[6], amount: row[4],
                                  contribution_type: 'pac')  if active_crp_identifiers.include?(row[3])
      rescue FasterCSV::MalformedCSVError
        puts 'skipping line: ' + $ERROR_INFO
      end
    end
  end
end

class Candidate < ActiveRecord::Base
  validates_presence_of :bioguide_id, :crp_id, :cycle
  validates_uniqueness_of :bioguide_id, scope: :cycle
  validates_uniqueness_of :crp_id, scope: :cycle
end
