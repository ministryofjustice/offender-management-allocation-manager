require "rails_helper"

describe "Info endpoinds" do
  describe "GET /info" do
    it "returns information reqgarding the deployed application" do
      stub_const('ENV',
                 ENV.to_hash.merge(
                   'GIT_BRANCH' => 'my/git/branch',
                   'BUILD_NUMBER' => '2014-12-25.0afbc7.af79nbc',
                   'PRODUCT_ID' => 'PROD1'
                 )
                )

      get "/info"

      expect(JSON.parse(response.body)).to eq({
        git: { branch: 'my/git/branch' },
        build: {
          artifact: 'offender-management-allocation-manager',
          version: '2014-12-25.0afbc7.af79nbc',
          name: 'offender-management-allocation-manager'
        },
        productId: 'PROD1'
      }.deep_stringify_keys)
    end
  end
end
