# frozen_string_literal: true

class RoshSummary
  attr_reader :status, :overall, :last_updated, :custody, :community

  def self.for(crn)
    return unable if crn.blank?

    parse_api_response(
      HmppsApi::AssessRisksAndNeedsApi.get_rosh_summary(crn)
    )
  rescue Faraday::ResourceNotFound
    missing
  rescue Faraday::Error => e
    Rails.logger.error("event=rosh_api_error,crn=#{crn}|#{e.message}")
    unable
  end

  def self.unable = new(status: :unable)
  def self.missing = new(status: :missing)

  def found? = status == :found
  def missing? = status == :missing
  def unable? = status == :unable

  #
  # All private methods below
  #
  def initialize(status:, overall: nil, last_updated: nil, custody: nil, community: nil)
    @status = status
    @overall = overall
    @last_updated = last_updated
    @custody = custody
    @community = community
  end

  def self.parse_api_response(risks)
    summary = risks.fetch('summary', {})

    return unable if summary['overallRiskLevel'].blank?

    new(
      status: :found,
      overall: summary['overallRiskLevel'].upcase,
      last_updated: risks['assessedOn'] ? Date.parse(risks['assessedOn']) : nil,
      custody: parse_risk_context(summary['riskInCustody']),
      community: parse_risk_context(summary['riskInCommunity']),
    )
  end

  def self.parse_risk_context(risk_data)
    levels = flatten_risk_levels(risk_data)

    {
      children: levels['Children'],
      public: levels['Public'],
      known_adult: ['Known Adult', 'Know adult'].filter_map { levels[it] }.first, # Cover capitalisation variants
      staff: levels['Staff'],
      prisoners: levels['Prisoners'],
    }.freeze
  end

  # Inverts { "HIGH" => ["Children", "Public"] } into { "Children" => "high", "Public" => "high" }
  def self.flatten_risk_levels(risk_data)
    return {} if risk_data.blank?

    risk_data.each_with_object({}) do |(level, groups), result|
      groups.each { |group| result[group] = level.downcase }
    end
  end

  private_class_method :parse_api_response, :parse_risk_context, :flatten_risk_levels, :new
end
