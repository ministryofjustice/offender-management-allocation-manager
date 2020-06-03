require 'rails_helper'

describe 'coworking routes', type: :routing do
  describe post: '/prisons/LEI/coworking' do
    it { is_expected.to route_to controller: 'coworking', action: 'create', prison_id: 'LEI' }
  end

  describe get: '/prisons/LEI/coworking/confirm/G123456/456765/654232' do
    it {
      expect(subject).to route_to controller: 'coworking',
                                  action: 'confirm',
                                  prison_id: 'LEI',
                                  nomis_offender_id: 'G123456',
                                  primary_pom_id: '456765',
                                  secondary_pom_id: '654232'
    }
  end

  describe get: '/prisons/LEI/coworking/G343234/new' do
    it {
      expect(subject).to route_to(controller: 'coworking',
                                  action: 'new',
                                  prison_id: 'LEI',
                                  nomis_offender_id: 'G343234')
    }
  end
end
