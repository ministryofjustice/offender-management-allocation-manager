module HighLevelMockingAndStubbingHelper
  # Create a mock MpcOffender and stub OffenderService to return it. Takes parameters to set on the mock, and generates
  # missing mocked data where not specified
  #
  # @return MpcOffender mock
  def stub_mpc_offender(**mpc_offender_attributes)
    mpc_offender_attributes.symbolize_keys!

    mpc_offender_attributes = {
      offender_no: FactoryBot.generate(:nomis_offender_id),
      com_responsible_date: Faker::Date.forward,
      first_name: Faker::Name.first_name,
      full_name_ordered: Faker::Name.name,
      date_of_birth: Faker::Date.backward,
      allocated_com_name: Faker::Name.name,
      allocated_com_email: Faker::Internet.email,
    }.merge(mpc_offender_attributes)

    mock_offender = instance_double(MpcOffender, **mpc_offender_attributes)
    allow(OffenderService).to receive(:get_offender).with(nomis_offender_id).and_return(mock_offender)
    mock_offender
  end
end

RSpec.configure do |config|
  config.include(HighLevelMockingAndStubbingHelper)
end
