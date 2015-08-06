module Lastic
  module Clauses
    %w[base simple composite coercion].each do |mod|
      require_relative "clauses/#{mod}"
    end
  end
end
