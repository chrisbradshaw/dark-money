# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_160_213_220_957) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'candidates', force: :cascade do |t|
    t.string   'bioguide_id'
    t.string   'crp_id'
    t.string   'cycle'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'candidates', %w(cycle bioguide_id), name: 'index_candidates_on_cycle_and_bioguide_id', using: :btree

  create_table 'committee_memberships', force: :cascade do |t|
    t.integer 'legislator_id'
    t.integer 'committee_id'
  end

  add_index 'committee_memberships', ['committee_id'], name: 'index_committee_memberships_on_committee_id', using: :btree
  add_index 'committee_memberships', %w(legislator_id committee_id), name: 'index_committee_memberships_on_legislator_id_and_committee_id', using: :btree

  create_table 'committees', force: :cascade do |t|
    t.string  'chamber'
    t.string  'keyword'
    t.string  'name'
    t.integer 'parent_id'
  end

  add_index 'committees', ['chamber'], name: 'index_committees_on_chamber', using: :btree
  add_index 'committees', ['keyword'], name: 'index_committees_on_keyword', using: :btree
  add_index 'committees', ['parent_id'], name: 'index_committees_on_parent_id', using: :btree

  create_table 'contributions', force: :cascade do |t|
    t.string   'bioguide_id'
    t.string   'crp_id'
    t.string   'industry'
    t.string   'cycle'
    t.integer  'amount'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'contributions', ['amount'], name: 'index_contributions_on_amount', using: :btree
  add_index 'contributions', ['bioguide_id'], name: 'index_contributions_on_bioguide_id', using: :btree
  add_index 'contributions', ['crp_id'], name: 'index_contributions_on_crp_id', using: :btree
  add_index 'contributions', %w(cycle bioguide_id), name: 'index_contributions_on_cycle_and_bioguide_id', using: :btree
  add_index 'contributions', %w(cycle industry), name: 'index_contributions_on_cycle_and_industry', using: :btree
  add_index 'contributions', ['cycle'], name: 'index_contributions_on_cycle', using: :btree
  add_index 'contributions', ['industry'], name: 'index_contributions_on_industry', using: :btree

  create_table 'districts', force: :cascade do |t|
    t.string  'state'
    t.string  'district'
    t.integer 'population'
    t.float   'males'
    t.float   'females'
    t.float   'blacks'
    t.float   'american_indians'
    t.float   'asians'
    t.float   'whites'
    t.float   'hispanics'
    t.float   'median_age'
    t.float   'median_household_income'
    t.float   'median_house_value'
    t.float   'median_rent'
  end

  add_index 'districts', %w(state district), name: 'index_districts_on_state_and_district', using: :btree

  create_table 'examples', force: :cascade do |t|
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'legislators', force: :cascade do |t|
    t.string   'chamber'
    t.string   'name'
    t.string   'gender'
    t.string   'district'
    t.string   'state'
    t.string   'party'
    t.string   'bioguide_id'
    t.boolean  'in_office'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string   'crp_id'
    t.string   'votesmart_id'
    t.string   'fec_id'
    t.string   'govtrack_id'
    t.string   'phone'
    t.string   'website'
    t.string   'twitter_id'
    t.string   'youtube_url'
    t.datetime 'birthdate'
  end

  add_index 'legislators', ['bioguide_id'], name: 'index_legislators_on_bioguide_id', using: :btree
  add_index 'legislators', %w(state district), name: 'index_legislators_on_state_and_district', using: :btree

  create_table 'roll_calls', force: :cascade do |t|
    t.string   'roll_call_type'
    t.text     'question'
    t.string   'result'
    t.string   'session'
    t.string   'year'
    t.string   'bill_identifier'
    t.string   'identifier'
    t.datetime 'held_at'
    t.datetime 'last_updated_at'
    t.integer  'congress'
    t.string   'bill_title'
    t.string   'chamber'
  end

  add_index 'roll_calls', ['bill_identifier'], name: 'index_roll_calls_on_bill_identifier', using: :btree
  add_index 'roll_calls', ['identifier'], name: 'index_roll_calls_on_identifier', using: :btree
  add_index 'roll_calls', ['roll_call_type'], name: 'index_roll_calls_on_roll_call_type', using: :btree

  create_table 'source_contributions', force: :cascade do |t|
    t.string   'cycle'
    t.string   'contributor'
    t.string   'crp_identifier'
    t.string   'industry_category'
    t.string   'amount'
    t.string   'contribution_type'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'source_contributions', ['contribution_type'], name: 'index_source_contributions_on_contribution_type', using: :btree
  add_index 'source_contributions', ['crp_identifier'], name: 'index_source_contributions_on_crp_identifier', using: :btree
  add_index 'source_contributions', ['cycle'], name: 'index_source_contributions_on_cycle', using: :btree
  add_index 'source_contributions', ['industry_category'], name: 'index_source_contributions_on_industry_category', using: :btree

  create_table 'sources', force: :cascade do |t|
    t.string  'name'
    t.string  'keyword'
    t.integer 'ttl'
    t.string  'source_name'
    t.string  'source_url'
  end

  add_index 'sources', ['keyword'], name: 'index_sources_on_keyword', using: :btree

  create_table 'updates', force: :cascade do |t|
    t.string   'source'
    t.string   'status'
    t.text     'message'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer  'elapsed_time'
  end

  add_index 'updates', %w(source status), name: 'index_updates_on_source_and_status', using: :btree

  create_table 'votes', force: :cascade do |t|
    t.string  'bioguide_id'
    t.string  'govtrack_id'
    t.string  'roll_call_identifier'
    t.string  'position'
    t.integer 'roll_call_id'
  end

  add_index 'votes', ['roll_call_id'], name: 'index_votes_on_roll_call_id', using: :btree
  add_index 'votes', ['roll_call_identifier'], name: 'index_votes_on_roll_call_identifier', using: :btree
end
