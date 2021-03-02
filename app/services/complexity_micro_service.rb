# :nocov:
class ComplexityMicroService
  class << self
    def get_complexity _offender_no
      raise NotImplementedError, 'ComplexityMicroService#get_complexity'
    end
  end
end
# :nocov:
