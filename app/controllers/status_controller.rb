class StatusController < ApplicationController
  def index
    @status = Allocation::Api.instance.get_status
  end
end
