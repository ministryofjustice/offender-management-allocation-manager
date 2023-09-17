module Utils::AwsUtils
module_function

  def self.extract_region_from_arn(topic_arn)
    matches = /\Aarn:aws:[a-z0-9]+:([a-z0-9-]+):/.match(topic_arn)
    raise ArgumentError, "bad ARN #{topic_arn}" unless matches

    matches[1]
  end
end
