# Custom RSpec matchers to help with testing POM and COM handover responsibilities

# A simple object to represent the responsibility of a POM or COM
OffenderManagerResponsibility = Struct.new(:responsible?, :supporting?)

# Assert responsibility: Responsible
# Example usage:
#   handover = HandoverDateService.handover(offender)
#   pom = OffenderManagerResponsibility.new(handover.pom_responsible?, handover.pom_supporting?)
#   expect(pom).to be_responsible
RSpec::Matchers.define :be_responsible do
  match do |responsibility|
    responsibility.responsible? && !responsibility.supporting?
  end
end

# Assert responsibility: Supporting
# Example usage:
#   handover = HandoverDateService.handover(offender)
#   pom = OffenderManagerResponsibility.new(handover.pom_responsible?, handover.pom_supporting?)
#   expect(pom).to be_supporting
RSpec::Matchers.define :be_supporting do
  match do |responsibility|
    responsibility.supporting? && !responsibility.responsible?
  end
end

# Assert that responsibility is needed (i.e. either Supporting or Responsible)
# Example usage:
#   handover = HandoverDateService.handover(offender)
#   com = OffenderManagerResponsibility.new(handover.com_responsible?, handover.com_supporting?)
#   expect(com).not_to be_involved # A COM isn't needed yet
RSpec::Matchers.define :be_involved do
  match do |responsibility|
    responsibility.supporting? || responsibility.responsible?
  end
end
