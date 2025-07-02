require 'rails_helper'

RSpec.describe OffenderHelper do
  let(:prison) { build(:prison) }
  let(:offender) do
    build(:mpc_offender, prison: prison, prison_record: api_offender, offender: build(:case_information).offender)
  end

  describe 'Digital Prison Services profile path' do
    it "formats the link to an offender's profile page within the Digital Prison Services" do
      expect(digital_prison_service_profile_path('AB1234A')).to eq("#{Rails.configuration.digital_prison_service_host}/offenders/AB1234A/quick-look")
    end
  end

  describe '#event_type' do
    let(:nomis_staff_id) { 456_789 }
    let(:nomis_offender_id) { 123_456 }

    let!(:allocation) do
      create(
        :allocation_history,
        prison: prison.code,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: nomis_staff_id,
        event: 'allocate_primary_pom'
      )
    end

    it 'returns the event in a more readable format' do
      expect(helper.last_event(allocation)).to eq("POM allocated - #{allocation.updated_at.strftime('%d/%m/%Y')}")
    end
  end

  describe '#pom_responsibility_label' do
    context 'when responsible' do
      let(:api_offender) { build(:hmpps_api_offender) }

      it 'shows responsible' do
        expect(helper.pom_responsibility_label(offender)).to eq('Responsible')
      end
    end

    context 'when supporting' do
      let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate_recall)) }

      it 'shows supporting' do
        expect(helper.pom_responsibility_label(offender)).to eq('Supporting')
      end
    end
  end

  describe 'generates labels for case owner' do
    context 'when Prison' do
      let(:api_offender) do
        build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail,
                                                            sentenceStartDate: Time.zone.today - 20.months,
                                                            automaticReleaseDate: Time.zone.today + 20.months))
      end

      it 'shows custody' do
        expect(helper.case_owner_label(offender)).to eq('Custody')
      end
    end

    context 'when Probation' do
      let(:api_offender) do
        build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, automaticReleaseDate: Time.zone.today))
      end

      it 'shows community' do
        expect(helper.case_owner_label(offender)).to eq('Community')
      end
    end
  end

  describe '#recommended_pom_type_label' do
    it "returns 'Prison officer' if RecommendService is PRISON_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
      offender = OpenStruct.new(immigration_case?: true, nps_case?: false, responsibility: nil)

      expect(helper.recommended_pom_type_label(offender)).to eq('Prison officer')
    end

    it "returns 'Probation officer' if RecommendService is PROBATION_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
      offender = OpenStruct.new(immigration_case?: false, nps_case?: true, tier: 'A', responsibility: nil)

      expect(helper.recommended_pom_type_label(offender)).to eq('Probation officer')
    end
  end

  describe '#complex_reason_label' do
    context 'when a prison POM' do
      # we need to set up this test to return a Prison POM recommendation; we are using an
      # Immigration case as they are always recommended to Prison POMs
      let(:offender) { OpenStruct.new(immigration_case?: true, nps_case?: false) }

      it "can get for a prison owned offender" do
        expect(helper.complex_reason_label(offender)).to eq('Prisoner assessed as not suitable for a prison officer POM')
      end
    end

    context 'when a probation POM' do
      let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate)) }
      let(:offender) do
        build(:mpc_offender, prison: prison, prison_record: api_offender, offender: build(:case_information, tier: 'A').offender)
      end

      it "can get for a probation owned offender" do
        expect(helper.complex_reason_label(offender)).to eq('Prisoner assessed as suitable for a prison officer POM despite tiering calculation')
      end
    end
  end

  describe '#non_recommended_pom_type_label' do
    it "returns 'Probation officer' when RecommendationService is PRISON_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
      subject = OpenStruct.new(immigration_case?: false, nps_case?: false, responsibility: nil)

      expect(helper.non_recommended_pom_type_label(subject)).to eq('Probation officer')
    end

    it "returns 'Prison officer' when RecommendationServicce is PROBATION_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
      subject = OpenStruct.new(immigration_case?: false, nps_case?: false, responsibility: nil)

      expect(helper.non_recommended_pom_type_label(subject)).to eq('Prison officer')
    end
  end

  describe '#format_allocation' do
    subject do
      helper.format_allocation(offender: offender, pom: pom, view_context: view_context)
    end

    let(:api_offender) { build(:hmpps_api_offender) }
    let(:pom) { double('StaffMember') }
    let(:notes) { 'a note' }
    let(:view_context) { double('view_context', full_name_ordered: '', unreverse_name: '', format_date: '') }
    let(:last_oasys_completed) { Time.zone.today }

    before do
      allow(helper).to receive(:last_oasys_completed).and_return(last_oasys_completed)
      allow(offender).to receive(:active_alert_labels).and_return(%w[bish bosh bash])
    end

    context 'when no last completed OASys' do
      let(:last_oasys_completed) { nil }

      it 'displays "No OASys information"' do
        expect(subject[:last_oasys_completed]).to eq('No OASys information')
      end
    end

    context 'when no responsibility handover' do
      before do
        allow(offender).to receive(:responsibility_handover_date).and_return(nil)
      end

      it 'displays "Unknown"' do
        expect(subject[:handover_completion_date]).to eq('Unknown')
      end
    end

    context 'when no COM name' do
      before do
        allow(offender).to receive(:allocated_com_name).and_return(nil)
      end

      it 'displays "Unknown"' do
        expect(subject[:com_name]).to eq('Unknown')
      end
    end
  end

  describe '#format_earliest_release_date' do
    subject { helper.format_earliest_release_date(date_hash) }

    context 'with expected date hash' do
      let(:date_hash) { { type: 'LED', date: Date.new(2000, 1, 1) } }

      it 'returns formatted output' do
        expect(subject).to eq('Licence expiry date: 01 Jan 2000')
      end
    end

    context 'with nil date hash' do
      let(:date_hash) { nil }

      it 'returns empty string' do
        expect(subject).to eq('')
      end
    end
  end
end
