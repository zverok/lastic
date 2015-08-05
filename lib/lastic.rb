module Lastic
  %w[clause fields query request].each do |mod|
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

