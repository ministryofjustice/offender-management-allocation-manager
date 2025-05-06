class Manage::DeallocatePomsController < ApplicationController
  before_action :authenticate_user, :ensure_admin_user
  before_action :fetch_allocations, only: %i[show confirm update]

  def index
    redirect_to manage_deallocate_pom_path(staff_id: params[:staff_id]) if params[:staff_id].present?
  end

  def show; end

  def confirm; end

  def update
    @allocations.each do |allocation|
      allocation.deallocate_primary_pom(event_trigger: AllocationHistory::MANUAL_CHANGE)
      allocation.deallocate_secondary_pom(event_trigger: AllocationHistory::MANUAL_CHANGE)
    end

    redirect_to manage_deallocate_pom_path(staff_id: params[:staff_id])
  end

private

  def fetch_allocations
    @allocations = AllocationHistory.for_pom(params[:staff_id])

    # optionally filter by prison
    if params[:prison].present? && params[:prison].in?(PrisonService::PRISONS.keys)
      @allocations = @allocations.at_prison(params[:prison])
    end
  end
end
