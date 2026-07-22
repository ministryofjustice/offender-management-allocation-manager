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

  describe '#last_event' do
    let(:nomis_staff_id) { 456_789 }
    let(:nomis_offender_id) { 123_456 }
    let(:first_allocation_date) { Time.zone.local(2026, 1, 10, 9, 0, 0) }
    let(:last_allocation_event_date) { Time.zone.local(2026, 2, 20, 14, 30, 0) }

    let!(:allocation) do
      create(
        :allocation_history,
        prison: prison.code,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: nomis_staff_id,
        event: 'allocate_primary_pom',
        created_at: first_allocation_date,
        updated_at: last_allocation_event_date
      )
    end

    it 'returns the event in a more readable format using the latest event date' do
      expect(helper.last_event(allocation)).to eq("POM allocated - #{last_allocation_event_date.strftime('%d/%m/%Y')}")
    end

    it 'falls back to created_at for CaseHistory-style objects without updated_at' do
      allocation_history = instance_double(
        CaseHistory,
        event: 'allocate_primary_pom',
        created_at: last_allocation_event_date
      )

      expect(helper.last_event(allocation_history)).to eq("POM allocated - #{last_allocation_event_date.strftime('%d/%m/%Y')}")
    end
  end

  describe '#event_type' do
    it 'returns the event in a more readable format' do
      expect(helper.event_type('allocate_primary_pom')).to eq('POM allocated')
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

  describe '#format_allocation' do
    subject do
      helper.format_allocation(offender: offender, pom: pom, view_context: view_context)
    end

    let(:api_offender) { build(:hmpps_api_offender) }
    let(:pom) { double('StaffMember') }
    let(:notes) { 'a note' }
    let(:view_context) do
      double('view_context').tap do |context|
        allow(context).to receive(:full_name_ordered).and_return('')
        allow(context).to receive(:unreverse_name).and_return('')
        allow(context).to receive(:format_date) { |date| date&.strftime('%d %b %Y') }
      end
    end
    let(:last_oasys_completed) { Time.zone.today }
    let(:handover_start_date) { Date.new(2027, 1, 1) }

    before do
      allow(helper).to receive(:last_oasys_completed).and_return(last_oasys_completed)
      allow(offender).to receive(:active_alert_labels).and_return(%w[bish bosh bash])
      allow(offender).to receive(:handover_start_date).and_return(handover_start_date)
    end

    it 'includes the handover start date' do
      expect(subject[:handover_start_date]).to eq('01 Jan 2027')
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

    context 'when no handover start date' do
      let(:handover_start_date) { nil }

      it 'displays "Unknown"' do
        expect(subject[:handover_start_date]).to eq('Unknown')
      end
    end

    context 'when prison alerts are unavailable' do
      before do
        allow(offender).to receive(:active_alert_labels).and_return(nil)
      end

      it 'displays the unavailable message' do
        expect(subject[:active_alerts]).to eq('This information is currently unavailable')
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
        expect(subject).to eq('Licence expiry date:<br>01 Jan 2000')
        expect(subject).to be_html_safe
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
