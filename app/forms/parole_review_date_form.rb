class ParoleReviewDateForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::AttributeAssignment
  extend ActiveModel::Callbacks

  include GovUkDateFields::ActsAsGovUkDate

  attribute :nomis_offender_id, :string
  attribute :parole_review_date, :date

  validates :parole_review_date, date: { after: proc { Date.yesterday }, allow_nil: true }

  define_model_callbacks :initialize

  acts_as_gov_uk_date :parole_review_date

  def initialize(args)
    @case_information = CaseInformation.find_by!(nomis_offender_id: args[:nomis_offender_id])
    run_callbacks(:initialize) { super }
  end

  def update(args)
    assign_attributes(args)
    save
  end

  def save
    if valid?
      @case_information.update!(parole_review_date: parole_review_date, manual_entry: true)
      true
    else
      false
    end
  end

  def new_record?
    false
  end

  def [](attr_name)
    instance_variable_get("@#{attr_name}".to_sym)
  end
end
