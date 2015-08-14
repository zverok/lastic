require 'hashie'

module Lastic
  class Search
    class Response
      attr_reader :raw
      
      def initialize(text)
        @raw = Hashie::Mash.new(JSON.parse(text))
      end

      def count
        raw.hits.total
      end

      def to_a
        raw.hits.hits
      end
    end
  end
end
