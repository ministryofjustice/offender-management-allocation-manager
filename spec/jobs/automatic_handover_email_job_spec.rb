# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutomaticHandoverEmailJob, type: :job do
  let(:active_ldu) { LocalDivisionalUnit.first }
  let(:staff_id) { 123456 }
  let(:email_address) { Faker::Internet.email }

  before do
    create(:local_divisional_unit, teams: [
      build(:team, case_information: case_info_records)])

    stub_auth_token
    offenders.each { |o| stub_offender(o) }

    stub_pom_emails staff_id, [email_address]
  end

  context 'with some offenders' do
    let(:case_info_records) { [case_info1, case_info2, case_info3] }
    let(:offenders) { [offender1, offender2, offender3] }

    # adding an early allocation is enough to put the offender within the desired handover window
    let!(:allocation1) { create(:allocation, nomis_offender_id: case_info1.nomis_offender_id, primary_pom_nomis_id: staff_id) }
    let(:case_info1) { build(:case_information) }
    let(:prison1) { build(:prison) }
    let(:offender1) {
      build(:nomis_offender, latestLocationId: prison1.code, offenderNo: case_info1.nomis_offender_id, firstName: 'One',
            sentence: attributes_for(:sentence_detail, :handover_in_8_days))
    }

    # This offender doesn't have an allocation (yet) - but still needs to be included
    let(:prison2) { build(:prison) }
    let(:case_info2) { build(:case_information) }
    let(:offender2) {
      build(:nomis_offender, latestLocationId: prison2.code, offenderNo: case_info2.nomis_offender_id, firstName: 'Two',
            sentence: attributes_for(:sentence_detail, :handover_in_4_days))
    }

    # This offender should come first as they have an earlier handover start date
    let(:case_info3) { build(:case_information) }
    let!(:allocation3) { create(:allocation,  nomis_offender_id: case_info3.nomis_offender_id, primary_pom_nomis_id: staff_id) }
    let(:prison3) { build(:prison) }
    let(:offender3) {
      build(:nomis_offender, latestLocationId: prison3.code, offenderNo: case_info3.nomis_offender_id, firstName: 'Three',
            sentence: attributes_for(:sentence_detail, :handover_in_6_days))
    }

    it 'sends an email for offenders handing over in the next 45 days' do
      expected_csv = [
        AutomaticHandoverEmailJob::HEADERS.join(','),
        (offender_csv_fields(offender2) +
        [case_info2.crn,
         case_info2.nomis_offender_id] +
            handover_fields(4.days) + [prison2.name, '', '']).join(','),
        (offender_csv_fields(offender3) +
            [case_info3.crn,
             case_info3.nomis_offender_id] + handover_fields(6.days) +
            [prison3.name, "\"#{allocation3.primary_pom_name}\"", email_address
        ]).join(','),
        (offender_csv_fields(offender1) +
            [case_info1.crn,
             case_info1.nomis_offender_id] + handover_fields(8.days) +
            [prison1.name, "\"#{allocation1.primary_pom_name}\"", email_address
        ]).join(','),
      ].map { |row| "#{row}\n" }.join

      expect_any_instance_of(CommunityMailer)
        .to receive(:pipeline_to_community)
              .with(ldu: active_ldu, csv_data: expected_csv).and_call_original
      described_class.perform_now active_ldu
    end
  end

  def handover_fields(offset)
    [today_plus(offset), today_plus(3.months + offset), today_plus(7.months + 15.days + offset)]
  end

  def offender_csv_fields(offender)
    ["\"#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}\""]
  end

  def today_plus(offset)
    (Time.zone.today + offset).to_s
  end

  context 'without offenders' do
    let(:case_info_records) { [] }
    let(:offenders) { [] }

    it 'sends the no data email' do
      expect_any_instance_of(CommunityMailer)
        .to receive(:pipeline_to_community_no_handovers)
              .with(active_ldu).and_call_original
      described_class.perform_now active_ldu
    end
  end
end
