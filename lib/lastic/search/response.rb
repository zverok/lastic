require 'hashie'

module Lastic
  class Search
    class Response
      attr_reader :raw
      
      def initialize(raw)
        @raw = case raw
        when String
          Hashie::Mash.new(JSON.parse(raw))
        when Hash
          Hashie::Mash.new(raw)
        else
          fail ArgumentError, "Can't initialize Response with #{raw.class}"
        end
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
