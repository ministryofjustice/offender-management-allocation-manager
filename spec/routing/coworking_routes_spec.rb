require 'rails_helper'

describe 'coworking routes', type: :routing do
  describe post: '/prisons/LEI/coworking/G123456' do
    it { is_expected.to route_to controller: 'coworking', action: 'create', prison_id: 'LEI', nomis_offender_id: 'G123456' }
  end

  describe get: '/prisons/LEI/coworking/G123456/confirm/654232' do
    it {
      expect(subject).to route_to controller: 'coworking',
                                  action: 'confirm',
                                  prison_id: 'LEI',
                                  nomis_offender_id: 'G123456',
                                  secondary_pom_nomis_id: '654232'
    }
  end
end
