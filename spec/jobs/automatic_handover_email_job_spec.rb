# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutomaticHandoverEmailJob, type: :job do
  let(:active_ldu) { LocalDivisionalUnit.first }
  let(:staff_id) { 123456 }
  let(:email_address) { Faker::Internet.email }

  before do
    # Need to freeze the date so that CRDs don't end up 29th of June - substracting 4 months is then
    # tricky (as 29th Feb doesn't exist) resulting in inconsistent test results(+- 1 day) as the date changes
    Timecop.travel Date.new(2020, 11, 5)

    create(:local_divisional_unit, teams: [
      build(:team, case_information: case_info_records)])

    stub_auth_token
    offenders.each do |o|
      stub_offender(o)

      expect(OffenderService).to receive(:get_offender).with(o.fetch(:offenderNo)).and_call_original
    end

    stub_pom_emails staff_id, [email_address]
  end

  after do
    Timecop.return
  end

  context 'with some offenders' do
    let(:case_info_records) { [case_info1, case_info2, case_info3, case_info4, case_info5, case_info6, case_info7] }
    let(:offenders) { [offender1, offender2, offender3, offender4, offender6, offender7] }

    let(:prison1) { build(:prison) }
    let(:case_info1) { build(:case_information) }
    let!(:allocation1) { create(:allocation, prison: prison1.code, nomis_offender_id: case_info1.nomis_offender_id, primary_pom_nomis_id: staff_id) }
    let(:offender1) {
      build(:nomis_offender, latestLocationId: prison1.code, offenderNo: case_info1.nomis_offender_id, firstName: 'One',
            sentence: attributes_for(:sentence_detail, :handover_in_8_days))
    }

    # This offender doesn't have an allocation (yet) - but still needs to be included
    let(:case_info2) { build(:case_information) }
    let(:offender2) {
      build(:nomis_offender, latestLocationId: prison1.code, offenderNo: case_info2.nomis_offender_id, firstName: 'Two',
            sentence: attributes_for(:sentence_detail, :handover_in_4_days))
    }

    # This offender should come first as they have an earlier handover start date
    let(:prison3) { build(:prison) }
    let(:case_info3) { build(:case_information) }
    let!(:allocation3) { create(:allocation, prison: prison3.code, nomis_offender_id: case_info3.nomis_offender_id, primary_pom_nomis_id: staff_id) }
    let(:offender3) {
      build(:nomis_offender, latestLocationId: prison3.code, offenderNo: case_info3.nomis_offender_id, firstName: 'Three',
            sentence: attributes_for(:sentence_detail, :handover_in_6_days))
    }

    # This offender is unsentenced and so should be excluded
    let(:case_info4) { build(:case_information) }
    let(:offender4) {
      build(:nomis_offender, latestLocationId: prison3.code, offenderNo: case_info4.nomis_offender_id, firstName: 'Four',
            sentence: attributes_for(:sentence_detail, :unsentenced, :handover_in_6_days))
    }

    # This offender isn't in NOMIS and so should be excluded
    let(:case_info5) { build(:case_information) }

    # This offender has an inactive allocation - but still needs to be included
    let(:prison6) { build(:prison) }
    let(:case_info6) { build(:case_information) }
    let!(:allocation6) { create(:allocation, :release, prison: prison6.code, nomis_offender_id: case_info6.nomis_offender_id) }
    let(:offender6) {
      build(:nomis_offender, latestLocationId: prison6.code, offenderNo: case_info6.nomis_offender_id, firstName: 'Six',
            sentence: attributes_for(:sentence_detail, :handover_in_3_days))
    }

    # This offender is in an inactive prison (one with no allocations at all) so should be excluded
    let(:prison7) { build(:prison) }
    let(:case_info7) { build(:case_information) }
    let(:offender7) {
      build(:nomis_offender, latestLocationId: prison7.code, offenderNo: case_info7.nomis_offender_id, firstName: 'Seven',
            sentence: attributes_for(:sentence_detail, :handover_in_4_days))
    }

    before do
      expect(OffenderService).to receive(:get_offender).with(case_info5.nomis_offender_id).and_return(nil)
    end

    it 'sends an email for offenders handing over in the next 45 days' do
      expected_csv = [
        AutomaticHandoverEmailJob::HEADERS.join(','),
        (offender_csv_fields(offender6) +
        [case_info6.crn,
         case_info6.nomis_offender_id] +
            handover_fields(3.days) + [prison6.name, '', '']).join(','),
        (offender_csv_fields(offender2) +
        [case_info2.crn,
         case_info2.nomis_offender_id] +
            handover_fields(4.days) + [prison1.name, '', '']).join(','),
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

    it 'doesnt send an email' do
      expect_any_instance_of(CommunityMailer)
        .not_to receive(:pipeline_to_community_no_handovers)
              .with(active_ldu).and_call_original
      described_class.perform_now active_ldu
    end
  end

  context 'with no-one in the handover window' do
    let(:case_info_records) { [case_info1] }
    let(:offenders) { [offender1] }

    let(:prison1) { build(:prison) }
    let(:case_info1) { build(:case_information) }
    let!(:allocation1) { create(:allocation, prison: prison1.code, nomis_offender_id: case_info1.nomis_offender_id, primary_pom_nomis_id: staff_id) }
    let(:offender1) {
      build(:nomis_offender, latestLocationId: prison1.code, offenderNo: case_info1.nomis_offender_id, firstName: 'One',
            sentence: attributes_for(:sentence_detail, :handover_in_46_days))
    }

    it 'sends the no data email' do
      expect_any_instance_of(CommunityMailer)
        .to receive(:pipeline_to_community_no_handovers)
              .with(active_ldu).and_call_original
      described_class.perform_now active_ldu
    end
  end
end
