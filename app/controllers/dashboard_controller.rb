# frozen_string_literal: true

class DashboardController < PrisonsApplicationController
  def index
    @is_pom = current_user_is_pom?

    @is_spo = current_user_is_spo?
  end
end
