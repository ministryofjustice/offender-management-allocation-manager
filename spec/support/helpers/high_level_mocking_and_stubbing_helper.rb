module HighLevelMockingAndStubbingHelper
  # Create a mock MpcOffender and stub OffenderService to return it. Takes parameters to set on the mock, and generates
  # missing mocked data where not specified
  #
  # @return MpcOffender mock
  def stub_mpc_offender(**mpc_offender_attributes)
    mpc_offender_attributes.symbolize_keys!

    offender_no = mpc_offender_attributes[:offender_no] ||= FactoryBot.generate(:nomis_offender_id)
    mpc_offender_attributes = {
      model: double(handover_date: Faker::Date.forward),
      first_name: Faker::Name.first_name,
      full_name_ordered: Faker::Name.name,
      date_of_birth: Faker::Date.backward,
      allocated_com_name: Faker::Name.name,
      allocated_com_email: Faker::Internet.email,
    }.merge(mpc_offender_attributes)

    mock_offender = instance_double(MpcOffender, **mpc_offender_attributes)
    allow(OffenderService).to receive(:get_offender).with(offender_no).and_return(mock_offender)
    FactoryBot.create :offender, nomis_offender_id: offender_no unless Offender.find_by_nomis_offender_id(offender_no)
    mock_offender
  end

  def sneaky_instance_double(the_class, *args, **kwargs)
    d = instance_double(the_class, *args, **kwargs.merge(is_a?: false))
    allow(d).to receive(:is_a?).with(the_class).and_return(true)
    d
  end
end

RSpec.configure do |config|
  config.include(HighLevelMockingAndStubbingHelper)
end
