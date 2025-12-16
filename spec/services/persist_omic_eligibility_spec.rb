describe 'PersistOmicEligibility' do
  before do
    eligible_offenders = [
      build(:nomis_offender, :inside_omic_policy, prisonerNumber: 'G1234AB'),
      build(:nomis_offender, :inside_omic_policy, prisonerNumber: 'G1234AC'),
    ]
    ineligible_offenders = [
      build(:nomis_offender, :outside_omic_policy, prisonerNumber: 'G1234AD'),
      build(:nomis_offender, :outside_omic_policy, prisonerNumber: 'G1234AE'),
      build(:nomis_offender, :outside_omic_policy, prisonerNumber: 'G1234AF'),
    ]
    stub_offenders_for_prison('LEI', eligible_offenders + ineligible_offenders)
  end

  def eligibility_of(nomis_offender_id) = OmicEligibility.find_by(nomis_offender_id:)&.eligible

  describe '.for_offenders_at' do
    it 'persists offenders inside omic policy as eligible' do
      PersistOmicEligibility.for_offenders_at('LEI')

      expect(eligibility_of('G1234AB')).to eq(true)
      expect(eligibility_of('G1234AC')).to eq(true)
    end

    it 'persists offenders outside omic policy as not eligible' do
      PersistOmicEligibility.for_offenders_at('LEI')

      expect(eligibility_of('G1234AD')).to eq(false)
      expect(eligibility_of('G1234AE')).to eq(false)
      expect(eligibility_of('G1234AF')).to eq(false)
    end
  end

  describe '.cleanup_records_updated_before' do
    before do
      create(:omic_eligibility, nomis_offender_id: 'G1234ZX', eligible: false, updated_at: 1.second.ago)
      create(:omic_eligibility, nomis_offender_id: 'G1234ZY', eligible: true, updated_at: 10.seconds.ago)
      create(:omic_eligibility, nomis_offender_id: 'G1234ZZ', eligible: false, updated_at: 1.hour.ago)
    end

    it 'deletes records which where not updated after the given time' do
      PersistOmicEligibility.cleanup_records_updated_before(30.minutes.ago)

      expect(eligibility_of('G1234ZZ')).to be_nil
    end

    it 'retains records which where updated after the given time' do
      PersistOmicEligibility.cleanup_records_updated_before(30.minutes.ago)

      expect(eligibility_of('G1234ZX')).to eq(false)
      expect(eligibility_of('G1234ZY')).to eq(true)
    end
  end
end
