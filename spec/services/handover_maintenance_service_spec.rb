RSpec.describe HandoverMaintenanceService do
  describe '#chase_ldu' do
    # Mocks describe 'happy path' - all conditions met to send chase email

    let!(:mailer) { double :mailer, deliver_later: nil }
    let!(:db_offender) { create(:offender) }
    # Sometimes a previous test leaks this prison into this test
    let!(:prison) { Prison.find_by_code('LEI') || create(:prison, name: 'TEST PRISON', code: 'LEI') }
    let!(:mpc_offender) do
      instance_double(MpcOffender,
                      :mpc_offender,
                      model: db_offender,
                      prison_id: prison.code,
                      nomis_offender_id: db_offender.nomis_offender_id,
                      offender_no: db_offender.nomis_offender_id,
                      ldu_name: Faker::Name.name,
                      ldu_email_address: Faker::Internet.email,
                      crn: Faker::Alphanumeric.alphanumeric,
                      allocated_com_name: nil,
                      first_name: Faker::Name.first_name,
                      last_name: Faker::Name.last_name)
    end
    let!(:handover) do
      create(:calculated_handover_date,
             offender: db_offender,
             responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
             reason: :determinate_short)
    end

    before do
      allow(PrisonService).to receive(:name_for).with(mpc_offender.prison_id).and_return('TEST PRISON NAME')
      allow(CommunityMailer).to receive(:with).and_return(
        double(:with_response, assign_com_less_than_10_months: mailer)
      )

      # Just over the threshold to allow chasing again
      db_offender.email_histories.create!(prison: mpc_offender.prison_id,
                                          name: Faker::Name.name,
                                          email: Faker::Internet.email,
                                          event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION,
                                          created_at: Time.zone.now.utc - 2.days - 1.second)
    end

    def chase_ldu
      described_class.chase_ldu(mpc_offender)
    end

    describe 'when not a short determinate sentence' do
      it 'does not send community chase email' do
        handover.update!(reason: 'determinate')
        chase_ldu
        expect(mailer).not_to have_received(:deliver_later)
      end
    end

    describe 'when not community responsible' do
      it 'does not send community chase email' do
        handover.update!(responsibility: CalculatedHandoverDate::CUSTODY_ONLY)
        chase_ldu
        expect(mailer).not_to have_received(:deliver_later)
      end
    end

    describe 'when LDU email not present' do
      it 'does not send community chase email' do
        allow(mpc_offender).to receive(:ldu_email_address).and_return(nil)
        chase_ldu
        expect(mailer).not_to have_received(:deliver_later)
      end
    end

    describe 'when COM is allocated' do
      it 'does not send community chase email' do
        allow(mpc_offender).to receive_messages(allocated_com_name: Faker::Name.name)
        chase_ldu
        expect(mailer).not_to have_received(:deliver_later)
      end
    end

    describe 'when last chased within last 2 days' do
      it 'does not send community chase email' do
        db_offender.email_histories.first.update!(created_at: Time.zone.now.utc - 2.days + 1.second)
        chase_ldu
        expect(mailer).not_to have_received(:deliver_later)
      end
    end

    describe 'when conditions are appropriate' do
      it 'sends community chase email', :aggregate_failures do
        chase_ldu
        expect(CommunityMailer).to have_received(:with).with(
          email: mpc_offender.ldu_email_address,
          crn_number: mpc_offender.crn,
          prison_name: 'TEST PRISON NAME',
          prisoner_name: "#{mpc_offender.first_name} #{mpc_offender.last_name}",
          prisoner_number: mpc_offender.nomis_offender_id,
        )
        expect(mailer).to have_received(:deliver_later)
      end
    end
  end
end
