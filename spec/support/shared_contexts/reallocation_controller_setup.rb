# frozen_string_literal: true

RSpec.shared_context 'with reallocation controller defaults' do
  let(:prison) { create(:prison) }
  let(:old_pom) { build(:pom, :prison_officer, staffId: 10_001, firstName: 'Old', lastName: 'Pom') }
  let(:new_pom) { build(:pom, :probation_officer, staffId: 10_002, firstName: 'New', lastName: 'Pom') }
  let(:poms) { [old_pom, new_pom] }
  let(:offenders_in_prison) { [offender] }
  let(:offender) do
    build(
      :nomis_offender,
      :inside_omic_policy,
      prisonId: prison.code,
      prisonerNumber: 'G1234AA',
      firstName: 'Alice',
      lastName: 'Zephyr',
      sentence: attributes_for(:sentence_detail, conditionalReleaseDate: '2028-04-01', releaseDate: '2029-04-01')
    )
  end
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:override_offender) do
    build(
      :nomis_offender,
      :inside_omic_policy,
      prisonId: prison.code,
      prisonerNumber: 'G5678BB',
      firstName: 'Bob',
      lastName: 'Amber',
      sentence: attributes_for(:sentence_detail, conditionalReleaseDate: '2028-05-01', releaseDate: '2029-05-01')
    )
  end
  let(:override_offender_no) { override_offender.fetch(:prisonerNumber) }

  before do
    stub_poms(prison.code, poms)
    stub_signed_in_spo_pom(prison.code, 99_999, 'spo-user')
    stub_offenders_for_prison(prison.code, offenders_in_prison)
    offenders_in_prison.each { |prisoner| stub_oasys_assessments(prisoner.fetch(:prisonerNumber)) }

    create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: old_pom.staffId)
    create(:pom_detail, :active, prison_code: prison.code, nomis_staff_id: new_pom.staffId)
    create_reallocation_case(offender_no, tier: 'A')
  end

  def create_reallocation_case(nomis_offender_id, tier:, primary_pom: old_pom)
    create(:case_information, offender: build(:offender, nomis_offender_id:), tier:)
    create(
      :allocation_history,
      prison: prison.code,
      nomis_offender_id:,
      primary_pom_nomis_id: primary_pom.staffId,
      primary_pom_name: primary_pom.full_name
    )
  end

  def bulk_reallocation_journey_data(selected_offender_ids:, override_offender_ids:, overrides: {},
                                     source_pom_id: old_pom.staffId, target_pom_id: new_pom.staffId)
    {
      source_pom_id:,
      target_pom_id:,
      selected_offender_ids:,
      override_offender_ids:,
      overrides:
    }
  end
end
