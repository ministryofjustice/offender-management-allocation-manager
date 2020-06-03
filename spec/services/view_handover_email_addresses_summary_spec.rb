require 'rails_helper'

describe ViewHandoverEmailAddressesSummary do
  let(:result) { subject.execute(offenders) }

  context 'with an empty list of offenders' do
    let(:offenders) { [] }

    it 'returns zero for each category' do
      expect(result).to eq(
        has_email_address: 0,
        missing_delius_record: 0,
        missing_team_link: 0,
        missing_team_information: 0,
        missing_local_delivery_unit: 0,
        missing_local_delivery_unit_email: 0
                           )
    end
  end

  context 'with one offender and no associated case information' do
    let(:offenders) { [double(offender_no: 1)] }

    it 'returns the right counts' do
      expect(result).to eq(
        has_email_address: 0,
        missing_delius_record: 1,
        missing_team_link: 0,
        missing_team_information: 0,
        missing_local_delivery_unit: 0,
        missing_local_delivery_unit_email: 0
                           )
    end
  end

  context 'with two offenders and no case information' do
    let(:offenders) { [double(offender_no: 1), double(offender_no: 2)] }

    it 'returns the right counts' do
      expect(result).to eq(
        has_email_address: 0,
        missing_delius_record: 2,
        missing_team_link: 0,
        missing_team_information: 0,
        missing_local_delivery_unit: 0,
        missing_local_delivery_unit_email: 0
                           )
    end
  end

  context 'with an offender that has case information but no team link' do
    let(:offenders) { [double(offender_no: 1)] }

    before { create(:case_information, nomis_offender_id: 1, team: nil) }

    it 'returns the right counts' do
      expect(result).to eq(
        has_email_address: 0,
        missing_delius_record: 0,
        missing_team_link: 1,
        missing_team_information: 0,
        missing_local_delivery_unit: 0,
        missing_local_delivery_unit_email: 0
                           )
    end
  end

  context 'with an offender that has case information with an orphaned team link' do
    let(:offenders) { [double(offender_no: 1)] }

    before do
      create(:case_information, nomis_offender_id: 1, team_id: 1)
      Team.destroy_all
    end

    it 'returns the right counts' do
      expect(result).to eq(
        has_email_address: 0,
        missing_delius_record: 0,
        missing_team_link: 0,
        missing_team_information: 1,
        missing_local_delivery_unit: 0,
        missing_local_delivery_unit_email: 0
                           )
    end
  end

  context 'with an offender that cannot be linked to a local delivery unit' do
    let(:offenders) { [double(offender_no: 1)] }

    before do
      create(:case_information, nomis_offender_id: 1, team_id: 10)
      team_without_ldu = build(:team, id: 10, local_divisional_unit: nil)
      team_without_ldu.save(validate: false)
    end

    it 'returns the right counts' do
      expect(result).to eq(
        has_email_address: 0,
        missing_delius_record: 0,
        missing_team_link: 0,
        missing_team_information: 0,
        missing_local_delivery_unit: 1,
        missing_local_delivery_unit_email: 0
                           )
    end
  end

  context 'with an offender that is linked to a local delivery unit which has no email address' do
    let(:offenders) { [double(offender_no: 1)] }

    before do
      create(:case_information, nomis_offender_id: 1, team_id: 10)

      ldu = create(:local_divisional_unit, email_address: nil)

      create(:team, id: 10, local_divisional_unit: ldu)
    end

    it 'returns the right counts' do
      expect(result).to eq(
        has_email_address: 0,
        missing_delius_record: 0,
        missing_team_link: 0,
        missing_team_information: 0,
        missing_local_delivery_unit: 0,
        missing_local_delivery_unit_email: 1
                           )
    end
  end

  context 'with an offender that has a local delivery unit email address' do
    let(:offenders) { [double(offender_no: 1)] }

    before do
      create(:case_information, nomis_offender_id: 1, team_id: 10)
      create(:team, id: 10, local_divisional_unit: create(:local_divisional_unit))
    end

    it 'returns the correct counts' do
      expect(result).to eq(
        has_email_address: 1,
        missing_delius_record: 0,
        missing_team_link: 0,
        missing_team_information: 0,
        missing_local_delivery_unit: 0,
        missing_local_delivery_unit_email: 0
                           )
    end
  end
end
