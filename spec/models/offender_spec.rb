# frozen_string_literal: true

RSpec.describe Offender, type: :model do
  let(:offender) { create(:offender) }

  describe '#nomis_offender_id' do
    subject { build(:offender) }

    # NOMIS offender IDs must be of the form <letter><4 numbers><2 letters>
    let(:valid_ids) { %w[A0000AA Z5432HD A4567CD] }

    let(:invalid_ids) do
      [
        'A 1234 AA', # no spaces allowed
        'E123456', # this is a nDelius CRN, not a NOMIS ID
        'A0000aA', # must be all uppercase
        '', # cannot be empty
        nil, # cannot be nil
        '1234567',
        'ABCDEFG',
      ]
    end

    it 'requires a valid NOMIS offender ID' do
      valid_ids.each do |id|
        subject.nomis_offender_id = id
        expect(subject).to be_valid
      end

      invalid_ids.each do |id|
        subject.nomis_offender_id = id
        expect(subject).not_to be_valid
      end
    end
  end

  describe '#early_allocations' do
    it { is_expected.to have_many(:early_allocations).dependent(:destroy) }

    context 'when not setup' do
      it 'is empty' do
        expect(offender.early_allocations).to be_empty
      end
    end

    context 'with Early Allocation assessments' do
      let!(:early_allocation) { create(:early_allocation, nomis_offender_id: offender.nomis_offender_id) }
      let!(:early_allocation2) { create(:early_allocation, nomis_offender_id: offender.nomis_offender_id) }

      it 'has some entries' do
        expect(offender.early_allocations).to eq([early_allocation, early_allocation2])
      end
    end

    describe 'sort order' do
      let(:creation_dates) { [1.year.ago, 1.day.ago, 1.month.ago].map(&:to_date) }

      before do
        # Deliberately create records out of order so we can assert that we order them correctly
        # This is unlikely to happen in real life because we use numeric primary keys – but it helps for this test
        creation_dates.each do |date|
          create(:early_allocation, nomis_offender_id: offender.nomis_offender_id, created_at: date)
        end
      end

      it 'sorts by date created (ascending)' do
        retrieved_dates = offender.early_allocations.map(&:created_at).map(&:to_date)
        expect(retrieved_dates).to eq(creation_dates.sort)
      end
    end
  end

  describe '#handover_progress_task_completion_data' do
    it 'gets the correct data when the checklist exists' do
      data = { t1: true, t2: false }
      allow(offender).to receive(:handover_progress_checklist).and_return(
        instance_double(HandoverProgressChecklist, task_completion_data: data)
      )
      expect(offender.handover_progress_task_completion_data).to eq(data)
    end

    it 'responds with all tasks incomplete if checklist model does not exist' do
      data = { t1: false, t2: false }
      mock = instance_double HandoverProgressChecklist, task_completion_data: data
      allow(offender).to receive(:build_handover_progress_checklist).and_return(mock)
      expect(offender.handover_progress_task_completion_data).to eq data
    end
  end

  describe '#handover_date' do
    it 'returns value from DB if that exists' do
      chd = FactoryBot.create :calculated_handover_date, nomis_offender_id: offender.nomis_offender_id
      expect(offender.handover_date).to eq chd.handover_date
    end

    it 'returns nil if saved value does not exist' do
      raise 'There should not be a calculated handover date' if offender.calculated_handover_date.present?

      expect(offender.handover_date).to be_nil
    end
  end

  describe 'handover type' do
    before do
      offender.build_case_information
      offender.build_calculated_handover_date
    end

    it 'is "missing" if there is no case information/probation record' do
      offender.case_information = nil
      expect(offender.handover_type).to eq 'missing'
      expect(offender.enhanced_handover?).to eq false
    end

    it 'is "missing" if no handover has been calculated yet' do
      offender.calculated_handover_date = nil
      expect(offender.handover_type).to eq 'missing'
      expect(offender.enhanced_handover?).to eq false
    end

    it 'is "enhanced" if enhanced resourcing field from case information is missing' do
      offender.case_information.enhanced_resourcing = nil
      expect(offender.handover_type).to eq 'enhanced'
      expect(offender.enhanced_handover?).to eq true
    end

    describe 'when sentence is short enough to be community responsible immediately' do
      it 'is "none" regardless of enhanced resourcing' do
        offender.case_information.enhanced_resourcing = true
        offender.calculated_handover_date.reason = 'determinate_short'
        expect(offender.handover_type).to eq 'none'
        expect(offender.enhanced_handover?).to eq false
      end

      it 'is "none" even if enhanced resourcing field from case information is missing' do
        offender.case_information.enhanced_resourcing = nil
        offender.calculated_handover_date.reason = 'determinate_short'
        expect(offender.handover_type).to eq 'none'
        expect(offender.enhanced_handover?).to eq false
      end
    end

    describe 'if sentence is not short enough to be community responsible immediately' do
      it 'is "standard" if standard resourcing' do
        offender.case_information.enhanced_resourcing = false
        expect(offender.handover_type).to eq 'standard'
        expect(offender.enhanced_handover?).to eq false
      end

      it 'is "enhanced" if enhanced resourcing' do
        offender.case_information.enhanced_resourcing = true
        expect(offender.handover_type).to eq 'enhanced'
        expect(offender.enhanced_handover?).to eq true
      end
    end
  end

  describe 'parole-related methods' do
    let(:incomplete_thd) { Time.zone.today + 2.years }
    let(:offender) { create(:offender, parole_reviews: [completed_parole_review, incomplete_parole_review]) }

    let(:completed_parole_review) do
      create(:parole_review, custody_report_due: Time.zone.today,
                             target_hearing_date: Time.zone.today,
                             hearing_outcome: 'Stay in closed [*]',
                             hearing_outcome_received_on: Time.zone.today,
                             review_status: 'Inactive')
    end

    let(:incomplete_parole_review) do
      create(:parole_review, custody_report_due: incomplete_thd,
                             target_hearing_date: incomplete_thd)
    end

    describe '#most_recent_parole_review' do
      it 'returns the most recent parole review' do
        expect(offender.most_recent_parole_review).to eq(incomplete_parole_review)
      end
    end

    describe 'Parole queries' do
      let(:completed_parole_review_1) do
        create(:parole_review, custody_report_due: Time.zone.today - 2.years,
                               target_hearing_date: Time.zone.today - 2.years,
                               hearing_outcome: 'Stay in closed [*]',
                               hearing_outcome_received_on: Time.zone.today - 2.years,
                               review_status: 'Inactive'
        )
      end

      let(:completed_parole_review_2) do
        create(:parole_review, custody_report_due: Time.zone.today,
                               target_hearing_date: Time.zone.today,
                               hearing_outcome: 'Not Applicable',
                               hearing_outcome_received_on: Time.zone.today,
                               review_status: 'Active'
        )
      end

      let(:offender) { create(:offender, parole_reviews: [completed_parole_review_1, completed_parole_review_2, incomplete_parole_review]) }

      context 'with a completed parole review whose outcome was received within the last 14 days' do
        it 'is the current_parole_review' do
          expect(offender.current_parole_review).to eq(completed_parole_review_2)
        end

        it 'any older parole reviews are previous parole reviews, in descending date order' do
          expect(offender.previous_parole_reviews).to match_array([completed_parole_review_1])
        end
      end

      context 'with a completed parole review whose outcome was received over 14 days ago' do
        let(:completed_parole_review_2) { create(:parole_review, custody_report_due: Time.zone.today - 15.days, target_hearing_date: Time.zone.today - 15.days, hearing_outcome: 'Stay in closed [*]', hearing_outcome_received_on: Time.zone.today - 15.days, review_status: 'Inactive') }

        it 'is the current_parole_review' do
          expect(offender.current_parole_review).to eq(incomplete_parole_review)
        end

        it 'any older parole reviews to the previous parole reviews, in descending date order' do
          expect(offender.previous_parole_reviews).to eq([completed_parole_review_2, completed_parole_review_1])
        end
      end
    end
  end

  describe '#responsible_pom_name' do
    it "returns the POMs full name using the AllocationHistory to look them up" do
      create(:allocation_history, :with_prison, offender:, primary_pom_name: "Pom Nomis")
      expect(offender.responsible_pom_name).to eq("Pom Nomis")
    end
  end

  describe '#responsible_com_name' do
    it "returns the COMs full name using the CaseInformation to look them up" do
      create(:case_information, offender:, com_name: 'Com Nomis')
      expect(offender.responsible_com_name).to eq("Com Nomis")
    end
  end
end
