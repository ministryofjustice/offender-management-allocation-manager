# Custom RSpec matchers to help with testing POM and COM handover responsibilities

# Assert responsibility: Responsible
# Example usage:
#   pom = HandoverDateService.handover(offender).custody
#   expect(pom).to be_responsible
RSpec::Matchers.define :be_responsible do
  match do |responsibility|
    responsibility.responsible? && !responsibility.supporting?
  end
end

# Assert responsibility: Supporting
# Example usage:
#   pom = HandoverDateService.handover(offender).custody
#   expect(pom).to be_supporting
RSpec::Matchers.define :be_supporting do
  match do |responsibility|
    responsibility.supporting? && !responsibility.responsible?
  end
end

# Assert that responsibility is needed (i.e. either Supporting or Responsible)
# Example usage:
#   com = HandoverDateService.handover(offender).community
#   expect(com).not_to be_involved # A COM isn't needed yet
RSpec::Matchers.define :be_involved do
  match do |responsibility|
    responsibility.supporting? || responsibility.responsible?
  end
end
