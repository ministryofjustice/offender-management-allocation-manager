require 'rails_helper'

describe RecommendationService do
  let(:tierA) {
    Nomis::Models::OffenderSummary.new.tap { |o| o.tier = 'A' }
  }
  let(:tierD) {
    Nomis::Models::OffenderSummary.new.tap { |o| o.tier = 'D' }
  }
  let(:poms) {
    [
      Nomis::Models::PrisonOffenderManager.new.tap { |p|
        p.first_name = 'Alice'
        p.position_description = 'Prison offender manager'
      },
      Nomis::Models::PrisonOffenderManager.new.tap { |p|
        p.first_name = 'Bob'
        p.position_description = 'Prison offender manager'
      },
      Nomis::Models::PrisonOffenderManager.new.tap { |p|
        p.first_name = 'Clare'
        p.position_description = 'Probation offender manager'
      },
      Nomis::Models::PrisonOffenderManager.new.tap { |p|
        p.first_name = 'Dave'
        p.position_description = 'Probation offender manager'
      }
    ]
  }

  it "can determine the best type of POM for Tier A" do
    expect(described_class.recommended_pom_type(tierA)).to eq(described_class::PROBATION)
  end

  it "can determine the best type of POM for Tier D" do
    expect(described_class.recommended_pom_type(tierD)).to eq(described_class::PRISON)
  end

  it "can partition POMs for a tier A offender" do
    a, b = described_class.recommended_poms(tierA, poms)
    expect(a.count).to eq(2)
    expect(b.count).to eq(2)
    expect(a[0].first_name).to eq('Clare')
    expect(a[1].first_name).to eq('Dave')
  end

  it "can partition POMs for a tier D offender" do
    a, b = described_class.recommended_poms(tierD, poms)
    expect(a.count).to eq(2)
    expect(b.count).to eq(2)
    expect(a[0].first_name).to eq('Alice')
    expect(a[1].first_name).to eq('Bob')
  end
end
