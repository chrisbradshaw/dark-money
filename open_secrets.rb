# frozen_string_literal: true
require 'httparty'
module OpenSecrets
  class Base
    include HTTParty
    base_uri 'http://www.opensecrets.org/api'
    default_params output: 'xml'
    format :xml
    # OpenSecrets Base constructor.  All OpenSecrets API classes inherit from this one which provides
    # the common initialization function.  For convenience you can skip providing an 'apikey' to the
    # constructor if you instead export a OPENSECRETS_API_KEY environment variable which is set to the
    # value of your API key.
    #
    # @option options [String] apikey (nil) an OpenSecrets API Key, this can also be provided in an OPENSECRETS_API_KEY shell environment variable for security and convenience.
    #
    def initialize(apikey = 'b67c6e3cc87c65b70206687ecda0cb1c')
      key =  apikey ||= ENV['OPENSECRETS_API_KEY']
      fail ArgumentError, 'You must provide an API Key' if key.nil? || key.empty?
      self.class.default_params apikey: key
    end
  end
  class Member < OpenSecrets::Base
    # Provides a list of Congressional legislators and associated attributes for specified subset (state, district or specific CID).
    #
    # See : https://www.opensecrets.org/api/?method=getLegislators&output=doc
    #
    # @option options [String] :id ("") two character state code, or 4 character district or specific CID
    #
    def get_legislators(options = {})
      fail ArgumentError, 'You must provide a :id option' if options[:id].nil? || options[:id].empty?
      options[:method] = 'getLegislators'
      self.class.get('/', query: options)
    end
    # Returns Personal Financial Disclosure (PFD) information for a member of Congress.
    #
    # See : http://www.opensecrets.org/api/?method=memPFDprofile&output=doc
    #
    # @option options [String] :cid ("") a CRP CandidateID
    # @option options [String] :year ("") Get data for specified year.
    #
    def pfd(options = {})
      fail ArgumentError, 'You must provide a :cid option' if options[:cid].nil? || options[:cid].empty?
      fail ArgumentError, 'You must provide a :year option' if options[:year].nil? || options[:year].empty?
      options[:method] = 'memPFDprofile'
      self.class.get('/', query: options)
    end
  end # member
  class Candidate < OpenSecrets::Base
    # Provides summary fundraising information for specified politician.
    #
    # See : http://www.opensecrets.org/api/?method=candSummary&output=doc
    #
    # @option options [String] :cid ("") a CRP CandidateID
    # @option options [optional, String] :cycle ("") blank values returns current cycle.
    #
    def summary(options = {})
      fail ArgumentError, 'You must provide a :cid option' if options[:cid].nil? || options[:cid].empty?
      options[:method] = 'candSummary'
      self.class.get('/', query: options)
    end
    # Provides the top organizations contributing to specified politician.
    #
    # See : http://www.opensecrets.org/api/?method=candContrib&output=doc
    #
    # @option options [String] :cid ("") a CRP CandidateID
    # @option options [optional, String] :cycle ("") 2008 or 2010.
    #
    def contributors(options = {})
      fail ArgumentError, 'You must provide a :cid option' if options[:cid].nil? || options[:cid].empty?
      options[:method] = 'candContrib'
      self.class.get('/', query: options)
    end
    # Provides the top industries contributing to a specified politician.
    #
    # See : http://www.opensecrets.org/api/?method=candIndustry&output=doc
    #
    # @option options [String] :cid ("") a CRP CandidateID
    # @option options [optional, String] :cycle ("") blank values returns current cycle.
    #
    def industries(options = {})
      fail ArgumentError, 'You must provide a :cid option' if options[:cid].nil? || options[:cid].empty?
      options[:method] = 'candIndustry'
      self.class.get('/', query: options)
    end
    # Provides total contributed to specified candidate from specified industry for specified cycle.
    #
    # See : http://www.opensecrets.org/api/?method=candIndByInd&output=doc
    #
    # @option options [String] :cid ("") a CRP CandidateID
    # @option options [String] :ind ("") a a 3-character industry code
    # @option options [optional, String] :cycle ("") 2012, 2014 available. leave blank for latest cycle
    #
    def contributions_by_industry(options = {})
      fail ArgumentError, 'You must provide a :cid option' if options[:cid].nil? || options[:cid].empty?
      fail ArgumentError, 'You must provide a :ind option' if options[:ind].nil? || options[:ind].empty?
      options[:method] = 'CandIndByInd'
      self.class.get('/', query: options)
    end
    # Provides sector total of specified politician's receipts.
    #
    # See : http://www.opensecrets.org/api/?method=candSector&output=doc
    #
    # @option options [String] :cid ("") a CRP CandidateID
    # @option options [optional, String] :cycle ("") blank values returns current cycle.
    #
    def sector(options = {})
      fail ArgumentError, 'You must provide a :cid option' if options[:cid].nil? || options[:cid].empty?
      options[:method] = 'candSector'
      self.class.get('/', query: options)
    end
  end # candidate
  class Committee < OpenSecrets::Base
    # Provides summary fundraising information for a specific committee, industry and Congress number.
    #
    # See : http://www.opensecrets.org/api/?method=congCmteIndus&output=doc
    #
    # @option options [String] :cmte ("") Committee ID in CQ format
    # @option options [String] :congno ("") Congress Number (like 110)
    # @option options [String] :indus ("") Industry code
    #
    def by_industry(options = {})
      fail ArgumentError, 'You must provide a :cmte option' if options[:cmte].nil? || options[:cmte].empty?
      fail ArgumentError, 'You must provide a :congno option' if options[:congno].nil? || options[:congno].empty?
      fail ArgumentError, 'You must provide a :indus option' if options[:indus].nil? || options[:indus].empty?
      options[:method] = 'congCmteIndus'
      self.class.get('/', query: options)
    end
  end # committee
  class Organization < OpenSecrets::Base
    # Look up an organization by name.
    #
    # See : https://www.opensecrets.org/api/?method=getOrgs&output=doc
    #
    # @option options [String] :org ("") name or partial name of organization requested
    #
    def get_orgs(options = {})
      fail ArgumentError, 'You must provide a :org option' if options[:org].nil? || options[:org].empty?
      options[:method] = 'getOrgs'
      self.class.get('/', query: options)
    end
    # Provides summary fundraising information for the specified organization id.
    #
    # See : https://www.opensecrets.org/api/?method=orgSummary&output=doc
    #
    # @option options [String] :org ("") CRP orgid (available via 'get_orgs' method)
    #
    def org_summary(options = {})
      fail ArgumentError, 'You must provide a :id option' if options[:id].nil? || options[:id].empty?
      options[:method] = 'orgSummary'
      self.class.get('/', query: options)
    end
  end # organization
end
CID = 'N00007360'.freeze # Nancy Pelosi
member = OpenSecrets::Member.new
puts "\n\nMEMBER : GET LEGISLATORS\n\n"
puts member.get_legislators(id: 'CA')['response']
puts "\n\nMEMBER : PFD PROFILE\n\n"
puts member.pfd(cid: CID, year: '2014')['response']
cand = OpenSecrets::Candidate.new
puts "\n\nCANDIDATE : SUMMARY\n\n"
puts cand.summary(cid: CID)['response']
puts "\n\nCANDIDATE : CONTRIBUTORS\n\n"
puts cand.contributors(cid: CID)['response']
puts "\n\nCANDIDATE : INDUSTRIES\n\n"
puts cand.industries(cid: CID)['response']
puts "\n\nCANDIDATE : CONTRIBUTIONS BY SPECIFIC INDUSTRY\n\n"
puts cand.contributions_by_industry(cid: CID, ind: 'K02')['response']
puts "\n\nCANDIDATE : SECTOR\n\n"
puts cand.sector(cid: CID)['response']
com = OpenSecrets::Committee.new
puts "\n\nCOMMITTEE\n\n"
puts com.by_industry(cmte: 'HARM', congno: '113', indus: 'F10')['response']
org = OpenSecrets::Organization.new
puts "\n\nORGANIZATION : GET ORGANIZATIONS\n\n"
puts org.get_orgs(org: 'people')['response']
puts "\n\nORGANIZATION : ORGANIZATION SUMMARY\n\n"
puts org.org_summary(id: 'D000023248')['response']