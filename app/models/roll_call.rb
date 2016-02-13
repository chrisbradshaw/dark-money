require 'hpricot'

class RollCall < ActiveRecord::Base
  has_many :votes, dependent: :delete_all
  validates_associated :votes
  validates_presence_of :question, :result, :identifier

  named_scope :bills, conditions: 'bill_identifier is not null'

  named_scope :listing, order: 'held_at desc'
  named_scope :search, lambda { |q|
    # for bill searching, support "H.R. 267", "HR 267", etc.
    bill_q = q.gsub(/[^\w\d]/, '')
    { conditions: [
      'question like ? or question like ? or question like ? or
      bill_identifier = ? or identifier like ? or bill_title like ?',
      "#{q}%", "% #{q}%", "%(#{q}%",
      bill_q.to_s, "%#{q}%", "%#{q}%"
    ]
    }
  }

  named_scope :passage, conditions: "roll_call_type LIKE '%Passage%'"
  named_scope :motion, conditions: "roll_call_type LIKE '%Motion%'"
  named_scope :amendment, conditions: "roll_call_type LIKE '%Amendment%'"
  named_scope :resolution, conditions: "roll_call_type LIKE '%Resolution%'"
  named_scope :cloture, conditions: "roll_call_type LIKE '%Cloture%'"
  named_scope :nomination, conditions: "roll_call_type LIKE '%Nomination%'"
  named_scope :conference_report, conditions: "roll_call_type LIKE '%Conference%'"

  named_scope :senate, conditions: "chamber = 'Senate'"
  named_scope :house, conditions: "chamber = 'House'"

  def self.sort(fields)
    fields.sort
  end

  def self.field_for(legislators, column)
    field = {}
    identifier = column

    vote_data = {}
    roll_call = RollCall.find_by_identifier identifier
    roll_call.votes.each { |vote| vote_data[vote.bioguide_id] = vote.position }

    legislators.each do |legislator|
      field[legislator.bioguide_id] = vote_data[legislator.bioguide_id]
    end

    field[:header] = roll_call.bill_identifier || "Vote #{roll_call.identifier}"
    field[:title] = roll_call.question

    field
  end

  def self.update(options = {})
    congress = options[:congress] || current_congress

    FileUtils.mkdir_p "data/govtrack/#{congress}"

    if system("rsync -az govtrack.us::govtrackdata/us/#{congress}/rolls data/govtrack/#{congress}") &&
       system("rsync -az govtrack.us::govtrackdata/us/#{congress}/bills.index.xml data/govtrack/#{congress}/bills.index.xml")
      roll_call_count = 0
      missing_bioguides = []

      # one hash to associate govtrack to bioguide ids
      legislators = {}
      ActiveRecord::Base.connection.execute('select legislators.govtrack_id, legislators.bioguide_id from legislators').each do |row|
        legislators[row[0]] = row[1]
      end

      # a hash to assign bill titles to roll_calls
      bill_titles = {}
      doc = Hpricot(open("data/govtrack/#{congress}/bills.index.xml"))
      (doc / :bill).each do |bill|
        bill_titles[bill_id_for(bill.attributes['type'], bill.attributes['number'])] = bill.attributes['title']
      end

      Dir.glob("data/govtrack/#{congress}/rolls/*.xml").each do |filename|
        identifier = File.basename filename, '.xml'
        doc = open(filename) { |f| Hpricot f }

        # For now, never update an existing roll call or associated vote data (old)
        # Later, use the updated timestamp to know whether the object should be updated (old)
        next if RollCall.find_by_identifier(identifier)

        roll_call = RollCall.new identifier: identifier

        # basic fields
        roll_call.held_at = Time.at(doc.at(:roll)[:when].to_i)
        roll_call.congress = doc.at(:roll)[:session].to_i
        roll_call.chamber = doc.at(:roll)[:where].titleize
        roll_call.roll_call_type = doc.at(:type).inner_text
        roll_call.question = doc.at(:question).inner_text
        roll_call.result = doc.at(:result).inner_text

        # associated bill identifier, if any
        if bill = doc.at(:bill)
          bill_id = bill_id_for bill[:type], bill[:number]
          roll_call.bill_identifier = bill_id
          roll_call.bill_title = bill_titles[bill_id]
        end

        puts "\n[#{identifier}] #{roll_call.question}"

        # vote data
        (doc / :voter).each do |elem|
          # skip cases
          next if elem[:id] == '0'

          if legislators[elem[:id]].nil?
            missing_bioguides << elem[:id]
            next
          end

          vote = roll_call.votes.build(
            position: elem[:value],
            bioguide_id: legislators[elem[:id]],
            govtrack_id: elem[:id],
            roll_call_identifier: identifier
          )
        end

        roll_call.save!
        roll_call_count += 1
      end

      success_msg = "#{roll_call_count} RollCalls created"
      if missing_bioguides.any?
        success_msg << "\nMissing bioguide_id for govtrack_id's: #{missing_bioguides.uniq.join(', ')}"
      end

      ['SUCCESS', success_msg]
    else
      ['FAILED', "Couldn't rsync files for Congress ##{congress} from GovTrack"]
    end
  rescue ActiveRecord::RecordInvalid => e
    roll_call = e.record
    votes = roll_call.votes.select { |v| v.errors.any? }
    if votes.any?
      ['FAILED', votes.first.errors]
    else
      ['FAILED', roll_call.errors]
    end
  rescue => e
    ['FAILED', "#{e.class}: #{e.message} - #{e.inspect}"]
  end

  private

  # Will return the # of the current congress (2007-2008 is 110th, 2009-2010 is 111th, etc.)
  # Simplistic, should change later
  def self.current_congress
    ((Time.now.year + 1) / 2) - 894
  end

  def self.bill_id_for(type, number)
    type_map = {
      h: 'HR',
      hr: 'HRES',
      hj: 'HJRES',
      sj: 'SJRES',
      hc: 'HCRES',
      s: 'S'
    }
    type = type_map[type.downcase.to_sym] || 'X'
    "#{type.upcase}#{number}"
  end
end

get '/roll_call/search' do
  @roll_calls = RollCall.search(params[:q]).listing.all unless params[:q].blank?

  if @roll_calls && @roll_calls.any?
    erb :"../sources/roll_call/table", locals: { roll_calls: @roll_calls }
  else
    'No results found.'
  end
end

class Vote < ActiveRecord::Base
  belongs_to :roll_call
  validates_presence_of :roll_call_identifier, :position
end

class String
  def titlecase
    gsub(/\b\w/) { $&.upcase }
  end
end
