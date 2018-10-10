class StatusController < ApplicationController
  def index
    @status = Allocation::Api.instance.fetch_status
  end
end
