require 'rails_helper'

describe HmppsApi::PrisonApi::OffenderApi do
  # These offenders should be allowed in because of their legal status
  let(:accepted_offenders) do
    [
      build(:nomis_offender, legalStatus: 'IMMIGRATION_DETAINEE'),
      build(:nomis_offender, legalStatus: 'INDETERMINATE_SENTENCE'),
      build(:nomis_offender, legalStatus: 'RECALL'),
      build(:nomis_offender, legalStatus: 'SENTENCED'),
    ]
  end

  # These offenders should be filtered out because of their legal status or imprisonment code
  let(:rejected_offenders) do
    [
      build(:nomis_offender, legalStatus: 'CIVIL_PRISONER'),
      build(:nomis_offender, legalStatus: 'CONVICTED_UNSENTENCED'),
      build(:nomis_offender, legalStatus: 'DEAD'),
      build(:nomis_offender, legalStatus: 'OTHER'),
      build(:nomis_offender, legalStatus: 'REMAND'),
      build(:nomis_offender, legalStatus: 'UNKNOWN'),
      build(:nomis_offender, legalStatus: 'SENTENCED', sentence: { imprisonmentStatus: 'A_FINE' })
    ]
  end

  describe 'List of offenders' do
    context 'with offenders who are on remand or unsentenced' do
      subject { described_class.get_offenders_in_prison(prison) }

      let(:prison) { create(:prison).code }

      let(:offenders) do
        (accepted_offenders + rejected_offenders).shuffle
      end

      before do
        stub_offenders_for_prison(prison, offenders)
      end

      it 'filters them out' do
        expect(subject.count).to eq(accepted_offenders.count)
        expect(subject.map(&:offender_no)).to match_array(accepted_offenders.map { |o| o[:prisonerNumber] })
      end
    end

    context 'when some offenders are temporarily out on ROTL' do
      subject { described_class.get_offenders_in_prison(prison) }

      let(:prison) { create(:prison).code }
      let(:in_offenders) { build_list(:nomis_offender, 3, prisonId: prison) }
      let(:out_offenders) { build_list(:nomis_offender, 2, :rotl, prisonId: prison) }
      let(:rotl_movements) do
        out_offenders.map do |o|
          attributes_for(:movement, :rotl, offenderNo: o[:prisonerNumber])
        end
      end

      before do
        stub_offenders_for_prison(prison, in_offenders + out_offenders, rotl_movements)
      end

      it 'loads the ROTL movement details' do
        expect(subject.count).to eq(5)
        rotls = subject.select { |o| o.latest_temp_movement_date.present? }
        expect(rotls.count).to eq(out_offenders.count)
        rotls.each do |offender|
          expect(offender.latest_temp_movement_date)
            .to eq rotl_movements.detect { |m| m[:offenderNo] == offender.offender_no }[:movementDate]
        end
      end
    end
  end

  describe 'Single offender' do
    describe '#get_offender' do
      subject { described_class.get_offender(offender_no) }

      let(:offender) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, recall: true)) }
      let(:offender_no) { offender.fetch(:prisonerNumber) }

      context "when offender exists" do
        before do
          stub_offender(offender)
        end

        it "can get a single offender's details including recall flag" do
          expect(subject).to be_instance_of(HmppsApi::Offender)
          expect(subject.recalled?).to eq(true)
        end

        it 'can get category info' do
          expect(subject.category_code).to eq('C')
          expect(subject.category_label).to eq('Cat C')
          expect(subject.category_active_since).to eq('29/06/2025'.to_date)
        end
      end

      context "when offender doesn't exist" do
        before do
          stub_non_existent_offender(offender_no)
        end

        it "fails the search" do
          expect(subject).to be_nil
        end
      end

      context 'when some offenders are temporarily out on ROTL' do
        let(:offender) { build(:nomis_offender, :rotl) }
        let(:rotl_movement) { attributes_for(:movement, :rotl, offenderNo: offender[:prisonerNumber]) }

        before do
          stub_offender(offender)
          stub_movements([rotl_movement])
        end

        it 'loads the ROTL movement details' do
          expect(subject.latest_temp_movement_date).to eq rotl_movement.fetch(:movementDate)
        end
      end
    end

    context 'when offender is on remand or unsentenced' do
      let(:offenders) do
        (accepted_offenders + rejected_offenders).shuffle
      end

      before do
        offenders.each { |o| stub_offender(o) }
      end

      it 'returns nil' do
        get_rejected_offenders = rejected_offenders.map { |o| described_class.get_offender(o[:prisonerNumber]) }
        get_accepted_offenders = accepted_offenders.map { |o| described_class.get_offender(o[:prisonerNumber]) }

        expect(get_rejected_offenders).to all be_nil
        expect(get_accepted_offenders).to all be_a(HmppsApi::Offender)
      end

      context 'with ignore_legal_status: true' do
        it "returns offenders who would usually be filtered out" do
          get_rejected_offenders = rejected_offenders.map { |o| described_class.get_offender(o[:prisonerNumber], ignore_legal_status: true) }
          get_accepted_offenders = accepted_offenders.map { |o| described_class.get_offender(o[:prisonerNumber], ignore_legal_status: true) }

          expect(get_rejected_offenders).to all be_a(HmppsApi::Offender)
          expect(get_accepted_offenders).to all be_a(HmppsApi::Offender)
        end
      end
    end
  end

  describe 'fetching an image' do
    let(:default_image_file) { described_class.default_image }
    let(:booking_id) { 1_153_753 }
    let(:image_id) { 1_340_556 }

    let(:details_uri) { "#{ApiHelper::T3}/offender-sentences/bookings" }
    let(:images_uri) { "#{ApiHelper::T3}/images/#{image_id}/data" }

    it "can get a user's jpg" do
      stub_request(:post, details_uri).with(body: "[#{booking_id}]").to_return(
        body: [{ bookingId: booking_id, facialImageId: image_id }].to_json
      )
      stub_request(:get, images_uri).to_return(body: 'image')

      response = described_class.get_image(booking_id)
      expect(response).to eq('image')
    end

    context 'when image is not found' do
      it 'returns the default image' do
        stub_request(:post, details_uri).with(body: "[#{booking_id}]").to_return(
          body: [{ bookingId: booking_id, facialImageId: image_id }].to_json
        )
        stub_request(:get, images_uri).to_return(status: 404)

        response = described_class.get_image(booking_id)
        expect(response).to eq(default_image_file)
      end
    end

    context 'when request for image returns empty' do
      it 'returns the default image' do
        stub_request(:post, details_uri).with(body: "[#{booking_id}]").to_return(
          body: [{ bookingId: booking_id, facialImageId: image_id }].to_json
        )
        stub_request(:get, images_uri).to_return(body: '')

        response = described_class.get_image(booking_id)
        expect(response).to eq(default_image_file)
      end
    end

    context 'when attribute `facialImageId` is missing' do
      it 'returns the default image' do
        stub_request(:post, details_uri).with(body: "[#{booking_id}]").to_return(
          body: [{ bookingId: booking_id }].to_json
        )

        response = described_class.get_image(booking_id)
        expect(response).to eq(default_image_file)
      end
    end
  end
end
