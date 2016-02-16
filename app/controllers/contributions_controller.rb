class ContributionsController < ApplicationController
  def index
    cand = OpenSecrets::Candidate.new
    @contributors = cand.contributors(cid: 'N00007360')['response']
    @contribution = cand.contributions_by_industry(cid: 'N00007360', ind: 'K02')['response']
  end

  def create
    

  end

end
