require 'rails_helper'

RSpec.describe BuildAllocationsController, type: :routing do
  let(:base_path) { '/prisons/LEI/prisoners/G1234AB/staff/1234/build_allocations' }

  {
    'new' => { get: 'new' },
    'override' => { get: 'override', put: 'update_override', patch: 'update_override' },
    'allocate' => { get: 'show', put: 'update', patch: 'update' },
  }.each do |path, actions|
    actions.each do |method, action|
      it "routes #{method.upcase} #{path} to #{action}" do
        expect(method => "#{base_path}/#{path}").to route_to(
          controller: 'build_allocations', action:, prison_id: 'LEI', prisoner_id: 'G1234AB', staff_id: '1234'
        )
      end
    end
  end

  it 'does not route unknown steps to allocation submission' do
    expect(put: "#{base_path}/unknown").not_to be_routable
  end
end
