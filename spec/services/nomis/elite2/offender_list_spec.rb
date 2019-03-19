require 'rails_helper'

describe Nomis::Elite2::OffenderList do
  let(:prison) { 'LEI' }

  it "Can simply retrieve all offenders from a prison", vcr: { cassette_name: 'offender_list_all_spec' } do
    offender_list = described_class.new(prison)
    offenders = offender_list.fetch
    expect(offenders.count).to eq(1168)
  end

  it "Can perform a simple filter", vcr: { cassette_name: 'offender_list_simple_filter_spec' } do
    offender_list = described_class.new(prison)
    offender_list.add_batch_filter(lambda { |offenders|
      offenders.select { |offender|
        offender.first_name[0] == 'C'
      }
    })
    offenders = offender_list.fetch

    expect(offenders.count).to eq(56)
  end

  it "Stops running filters when no records", vcr: { cassette_name: 'offender_list_simple_stop_spec' } do
    offender_list = described_class.new(prison)
    offender_list.add_batch_filter(lambda { |offenders|
      offenders.select { |_| false }
    })
    offenders = offender_list.fetch

    expect(offenders.count).to eq(0)
  end

  it "Can add to records", vcr: { cassette_name: 'offender_list_add_to_records_spec' } do
    mapped_tiers = {
      'G1103VT' => 'A'
    }

    offender_list = described_class.new(prison)
    offender_list.add_batch_filter(lambda { |offenders|
      offenders.map { |offender|
        offender.tier = mapped_tiers[offender.offender_no]
        offender
      }
    })
    offenders = offender_list.fetch

    any_with_tier = offenders.any? { |offender| offender.tier.present? }
    expect(offenders.count).to eq(1168)
    expect(any_with_tier).to be true
  end

  it "can perform filter+update", vcr: { cassette_name: 'offender_list_filterupdate_spec' } do
    filter_map_func = lambda { |offenders|
      offender_ids = offenders.map(&:offender_no)
      sentence_details = if offenders.count > 0
                           Nomis::Elite2::OffenderApi.get_bulk_sentence_details(
                             offender_ids
                           )
                         else
                           {}
                         end

      offenders.select { |offender|
        offender.release_date = sentence_details[offender.offender_no].release_date
        offender.release_date.present?
      }
    }

    offender_list = described_class.new(prison)
    offender_list.add_batch_filter(filter_map_func)
    offender_results = offender_list.fetch

    expect(offender_results.count).to eq(623)
  end

  it "can run several filters", vcr: { cassette_name: 'offender_list_several_filters_spec' } do
    # Filter our results that have no release date
    filter_map_func = lambda { |offenders|
      offender_ids = offenders.map(&:offender_no)
      sentence_details = if offenders.count > 0
                           Nomis::Elite2::OffenderApi.get_bulk_sentence_details(
                             offender_ids
                           )
                         else
                           {}
                         end

      offenders.select { |offender|
        offender.release_date = sentence_details[offender.offender_no].release_date
        offender.release_date.present?
      }
    }

    # Add a tier to offenders where we have them
    mapped_tiers = {
      'G1103VT' => 'A'
    }
    add_tiers = lambda { |offenders|
      offenders.map { |offender|
        offender.tier = mapped_tiers[offender.offender_no]
        offender
      }
    }

    offender_list = described_class.new(prison)
    offender_list.add_batch_filter(filter_map_func)
    offender_list.add_batch_filter(add_tiers)
    offender_results = offender_list.fetch

    expect(offender_results.count).to eq(623)
  end
end
