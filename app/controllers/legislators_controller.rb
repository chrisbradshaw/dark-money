class LegislatorsController < ApplicationController

def index
  member = OpenSecrets::Member.new
  @member= member.get_legislators(id: 'CA')['response']
end

end
