require 'rails_helper'

RSpec.describe PrisonsApplicationController, type: :controller do
  describe 'referrer' do
    context 'when referrer is set to null' do
      it 'redirects to the root_path of /' do
        allow(request).to receive(:referer).and_return(nil)
        
        expect(subject.__send__(:referrer)).to eq('/')
      end
    end

    context 'when the referrer is not null' do
      it 'sets the referrer to the non-null path' do
        allow(request).to receive(:referer).and_return('/fred')

        expect(subject.__send__(:referrer)).to eq('/fred')
      end
    end
  end
end