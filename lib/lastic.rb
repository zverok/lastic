require 'json'

require_relative 'lastic/refinements'

module Lastic
  %w[clauses fields query aggregations request search].each do |mod|
    require_relative "lastic/#{mod}"
  end

  class << self
    def field(*names)
      Field.new(*names)
    end

    def fields(*names)
      Fields.new(*names)
    end
  end
end

