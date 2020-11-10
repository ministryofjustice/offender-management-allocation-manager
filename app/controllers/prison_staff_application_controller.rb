# frozen_string_literal: true

class PrisonStaffApplicationController < PrisonsApplicationController
  before_action :ensure_signed_in_pom_is_this_pom, :load_pom

private

  def load_pom
    @pom = StaffMember.new(@prison, staff_id)
  end

  def ensure_signed_in_pom_is_this_pom
    unless staff_id == @staff_id || current_user_is_spo?
      redirect_to '/401'
    end
  end

  def staff_id
    params.fetch(:staff_id).to_i
  end
end
