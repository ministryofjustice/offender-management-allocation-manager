require 'rails_helper'

describe Manage::DeallocatePomsController do
  describe 'PATCH update' do
    before do
      create(:allocation_history, prison: 'LEI', nomis_offender_id: 'GA1234', primary_pom_nomis_id: 456_456, secondary_pom_nomis_id: 999_999)
      create(:allocation_history, prison: 'LEI', nomis_offender_id: 'GA2345', primary_pom_nomis_id: 456_456)
      create(:allocation_history, prison: 'LEI', nomis_offender_id: 'GA3456', primary_pom_nomis_id: 456_456)
      create(:allocation_history, prison: 'WHI', nomis_offender_id: 'GA4567', primary_pom_nomis_id: 456_456)
      create(:allocation_history, prison: 'LEI', nomis_offender_id: 'GA5678', primary_pom_nomis_id: 999_999)

      stub_sso_data('LEI', roles: [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE])
    end

    specify 'deallocates all cases for specified POM' do
      patch :update, params: { staff_id: 456_456 }
      expect(AllocationHistory.for_pom(456_456).count).to eq(0)
    end

    specify 'deallocates from both primary and secondary roles as allocated POM' do
      patch :update, params: { staff_id: 999_999 }
      expect(AllocationHistory.for_pom(999_999).count).to eq(0)
      expect(AllocationHistory.where(secondary_pom_nomis_id: 999_999).count).to eq(0)
      expect(AllocationHistory.where(primary_pom_nomis_id: 999_999).count).to eq(0)
    end

    specify 'deallocates all cases for specified POM in a given prison only when prison specified' do
      patch :update, params: { staff_id: 456_456, prison: 'WHI' }
      pom_allocations = AllocationHistory.for_pom(456_456)
      expect(pom_allocations.count).to eq(3)
      expect(pom_allocations.at_prison('LEI').count).to eq(3)
      expect(pom_allocations.at_prison('WHI').count).to eq(0)
    end

    specify 'allocations for other POMs remain untouched' do
      patch :update, params: { staff_id: 456_456 }
      expect(AllocationHistory.for_pom(999_999).count).to eq(1)
    end
  end
end
