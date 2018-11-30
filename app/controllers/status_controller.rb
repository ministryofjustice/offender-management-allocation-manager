class StatusController < ApplicationController
  def index
    @status = Allocation::Api.status
  end
end
