# frozen_string_literal: true

require 'rails_helper'

describe PrisonOffenderManagerService do
  let!(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }

  let(:other_staff_id) { 485_637 }
  let(:staff_id) { 485_758 }

  let(:poms) do
    [
      build(:pom, :probation_officer, staffId: staff_id, firstName: 'PO', lastName: 'MOIC'),
      build(:pom, :prison_officer, staffId: other_staff_id, firstName: 'POM', lastName: 'MOIC'),
    ]
  end

  before(:each) do
    PomDetail.create(prison_code: 'LEI', nomis_staff_id: other_staff_id, working_pattern: 1.0, status: 'inactive')

    stub_poms(prison.code, poms)
  end

  describe '#get_list_of_poms' do
    subject do
      prison.get_list_of_poms
    end

    let(:po_staff) { subject.detect { |x| x.first_name == 'PO' } }

    it "can get a list of POMs" do
      expect(subject).to be_a(Enumerable)
      expect(subject.count { |pom| pom.status == 'active' }).to eq(1)
      expect(po_staff.probation_officer?).to eq(true)
    end
  end

  describe '#get_single_pom' do
    context 'when the POM exists' do
      before(:each) do
        stub_filtered_pom(prison.code, poms.first)
      end

      it "can fetch a single POM for a prison" do
        pom = prison.get_single_pom(staff_id)
        expect(pom.staff_id).to eq(staff_id)
      end
    end

    context 'when the POM does not exist' do
      before(:each) do
        stub_inexistent_filtered_pom(prison.code, 1234)
      end

      it "raises an exception when fetching a pom if they are not a POM" do
        expect {
          prison.get_single_pom(1234)
        }.to raise_exception(StandardError, /^Failed to find POM/)
      end
    end
  end

  describe 'fetch_pom_name' do
    it 'fetches the ordered POM name from NOMIS' do
      expect(described_class.fetch_pom_name(staff_id)).to eq('Po Moic')
    end

    it 'fetches the unordered POM name from NOMIS' do
      expect(described_class.fetch_pom_name(staff_id, ordered: false)).to eq('MOIC, PO')
    end
  end
end
