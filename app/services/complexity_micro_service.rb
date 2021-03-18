# frozen_string_literal: true

# :nocov:
class ComplexityMicroService
  class << self
    def get_complexity _offender_no
      raise NotImplementedError, 'ComplexityMicroService#get_complexity'
    end

    def save offender_no, level:, username:, reason:
      raise NotImplementedError "ComplexityMicroService#save for #{offender_no} Lev #{level} user #{username} reason #{reason}"
    end
  end
end
# :nocov:
