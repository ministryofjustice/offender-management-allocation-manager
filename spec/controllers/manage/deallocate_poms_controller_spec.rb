require 'rails_helper'

describe Manage::DeallocatePomsController do
  before do
    create(:allocation_history, id: 1, prison: 'LEI', nomis_offender_id: 'GA1234', primary_pom_nomis_id: 456_456, secondary_pom_nomis_id: 999_999)
    create(:allocation_history, id: 2, prison: 'LEI', nomis_offender_id: 'GA2345', primary_pom_nomis_id: 456_456)
    create(:allocation_history, id: 3, prison: 'LEI', nomis_offender_id: 'GA3456', primary_pom_nomis_id: 456_456)
    create(:allocation_history, id: 4, prison: 'WHI', nomis_offender_id: 'GA4567', primary_pom_nomis_id: 456_456)
    create(:allocation_history, id: 5, prison: 'LEI', nomis_offender_id: 'GA5678', primary_pom_nomis_id: 999_999)

    stub_sso_data('LEI', roles: [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE])
  end

  describe 'GET search' do
    specify 'can display a specific POMs allocated cases' do
      get :search, params: { staff_id: 999_999 }
      expect(assigns(:allocations).count).to eq(2)
      expect(assigns(:allocations).map(&:id)).to eq([1, 5])
    end

    specify 'can display a specific allocated case' do
      get :search, params: { case_id: 'GA2345' }
      expect(assigns(:allocations).count).to eq(1)
      expect(assigns(:allocations).map(&:id)).to eq([2])
    end
  end

  describe 'PATCH confirm' do
    specify 'displays the selected allocations back to the user' do
      patch :confirm, params: { allocation_ids: ['1', '2', '4', '5'] }
      expect(assigns(:allocations).count).to eq(4)
      expect(assigns(:allocations).map(&:id)).to eq([1, 2, 4, 5])
    end
  end

  describe 'PATCH update' do
    specify 'deallocates primary and secondary POM from the given allocations' do
      patch :update, params: { allocation_ids: ['1', '2'] }
      alloc_1 = AllocationHistory.find(1)
      expect(alloc_1.primary_pom_nomis_id).to be_nil
      expect(alloc_1.secondary_pom_nomis_id).to be_nil
      alloc_2 = AllocationHistory.find(2)
      expect(alloc_2.primary_pom_nomis_id).to be_nil
      expect(alloc_2.secondary_pom_nomis_id).to be_nil
      expect(AllocationHistory.find(3).primary_pom_nomis_id).to eq(456_456)
      expect(AllocationHistory.find(4).primary_pom_nomis_id).to eq(456_456)
      expect(AllocationHistory.find(5).primary_pom_nomis_id).to eq(999_999)
    end
  end
end
