require 'rails_helper'

RSpec.describe 'robots tag header' do
  it "blocks all crawlers" do
    get '/'
    expect(response.headers["X-Robots-Tag"]).to eq "noindex, nofollow"
  end
end
