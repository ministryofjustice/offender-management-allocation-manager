# frozen_string_literal: true

class DashboardController < PrisonsApplicationController
  def index
    @is_pom = POMService::GetSignedInPom.call(
      active_prison, current_user
    ).present?
  end
end
