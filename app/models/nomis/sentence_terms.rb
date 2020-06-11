# frozen_string_literal: true

module Nomis
  class SentenceTerms
    include Deserialisable

    attr_reader :sentence_type, :sentence_type_description

    class << self
      def from_json(payload)
        SentenceTerms.new.tap do |obj|
          obj.load_from_json(payload)
        end
      end
    end

    def load_from_json(payload)
      @sentence_type = payload.fetch('sentenceType')
      @sentence_type_description = payload.fetch('sentenceTypeDescription')
      @life_sentence = payload.fetch('lifeSentence')
    end

    def indeterminate_sentence?
      @life_sentence
    end
  end
end
