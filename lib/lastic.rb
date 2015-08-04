module Lastic
  class Field
    attr_reader :name
    
    def initialize(*names)
      @name = names.join('.')
    end

    def ==(other)
      other.is_a?(Field) && name == other.name
    end

    def to_s
      name
    end

    def term(value)
      Clause.new(:term, self, value)
    end

    def terms(*values)
      Clause.new(:terms, self, values)
    end

    def wildcard(value)
      Clause.new(:wildcard, self, value)
    end
  end

  class Clause
    attr_reader :op, :field, :value
    
    def initialize(op, field, value)
      @op, @field, @value = op, field, value
    end

    def to_h
      {@op.to_s => {@field.to_s => @value}}
    end
  end
end
