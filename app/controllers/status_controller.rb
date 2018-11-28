class StatusController < ApplicationController
  def index
    @status = Allocation::Api.get_status
  end
end
