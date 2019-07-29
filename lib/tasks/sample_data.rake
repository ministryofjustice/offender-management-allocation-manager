# frozen_string_literal: true

require 'csv'
require_relative '../../lib/delius/sampler'


# This Rake task allows for the generation of some sample delius data
# as a CSV (which can then be turned into an XLSX) with data from the
# T3 Elite2 endpoint.  This will allow for the matching of this sample
# data to that Elite2 data.
namespace :sample_data do
  desc 'Generates fake delius data from the T3 API'
  task :generate, [:output_file, :count] => :environment do |_task, args|
    if defined?(Rails) && Rails.env.development?
      #Rails.logger = Logger.new(STDOUT)
    end

    sampler = Delius::Sampler.new(args[:output_file])
    sampler.generate(args[:count].to_i)
  end
end
