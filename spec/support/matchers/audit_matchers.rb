RSpec::Matchers.define :have_audited do |event, outcome: 'SUCCESS', **attributes|
  match do |events|
    values_match?(
      [
        a_hash_including(attributes.merge(what: "#{event}_ATTEMPT")),
        a_hash_including(attributes.merge(what: "#{event}_#{outcome}")),
      ],
      events
    )
  end

  failure_message do |events|
    "expected #{event}_ATTEMPT and #{event}_#{outcome} with #{attributes.inspect}, got #{events.inspect}"
  end
end
