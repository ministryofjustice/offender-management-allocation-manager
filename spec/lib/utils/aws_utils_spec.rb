RSpec.describe Utils::AwsUtils do
  describe '#extract_region_from_arn' do
    it 'extracts the region from a well-formatted ARN' do
      expect(described_class.extract_region_from_arn('arn:aws:s3:eu-west-1:000000000000:test-name')).to eq 'eu-west-1'
    end

    it 'errors if ARN is malformed' do
      expect { described_class.extract_region_from_arn('arn:aws:s3:eu-west-1') }.to raise_error(ArgumentError)
    end
  end
end
