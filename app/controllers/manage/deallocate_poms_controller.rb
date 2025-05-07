class Manage::DeallocatePomsController < ApplicationController
  before_action :authenticate_user, :ensure_admin_user

  def search
    @allocations = if params[:staff_id].present?
                     AllocationHistory.for_pom(params[:staff_id])
                   elsif params[:case_id].present?
                     AllocationHistory.where(nomis_offender_id: params[:case_id])
                   else
                     []
                   end
  end

  def confirm
    @allocations = AllocationHistory.where(id: params[:allocation_ids])
  end

  def update
    Array(params[:allocation_ids]).each do |allocation_id|
      allocation = AllocationHistory.find(allocation_id)
      allocation.deallocate_primary_pom(event_trigger: AllocationHistory::MANUAL_CHANGE)
      allocation.deallocate_secondary_pom(event_trigger: AllocationHistory::MANUAL_CHANGE)
    end

    redirect_to manage_deallocate_poms_path
  end
end
