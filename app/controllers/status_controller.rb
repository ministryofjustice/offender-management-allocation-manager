class StatusController < ApplicationController
  before_action :authenticate_user
  def index
    @status = Allocation::Api.status
  end
end
