module Lastic
  class Clause
    attr_reader :field
    
    def initialize(field)
      @field = field
    end

    def ==(other)
      self.class == other.class && field == other.field
    end
  end

  class Binary < Clause
    attr_reader :operand
    
    def initialize(field, operand)
      super(field)
      @operand = operand
    end

    def ==(other)
      super && operand == other.operand
    end
  end

  class Term < Binary
  end

  class Terms < Binary
    def initialize(field, *values)
      super(field, values.flatten)
    end
  end

  class Wildcard < Binary
  end

  class Regexp < Binary
  end

  class Exists < Clause
  end

  class Range < Clause
    attr_reader :range
    
    def initialize(field, gt: nil, gte: nil, lt: nil, lte: nil)
      super(field)
      @range = {gt: gt, gte: gte, lt: lt, lte: lte}.reject{|k,v| !v}
    end

    def ==(other)
      super && range == other.range
    end

    def >(value)
      Range.new(field, range.merge(gt: value))
    end

    def >=(value)
      Range.new(field, range.merge(gte: value))
    end

    def <(value)
      Range.new(field, range.merge(lt: value))
    end

    def <=(value)
      Range.new(field, range.merge(lte: value))
    end
  end

  module Clauses
    def term(value)
      Term.new(self, value)
    end

    def terms(*values)
      Terms.new(self, *values)
    end

    def wildcard(value)
      Wildcard.new(self, value)
    end

    def regexp(value)
      Regexp.new(self, value)
    end

    def range(gt: nil, gte: nil, lt: nil, lte: nil)
      Range.new(self, gt: gt, gte: gte, lt: lt, lte: lte)
    end

    def exists
      Exists.new(self)
    end

    def ===(value)
      case value
      when ::Regexp
        regexp(value)
      when ::Array
        terms(*value)
      when ::Range
        if value.exclude_end?
          range(gte: value.begin, lt: value.end)
        else
          range(gte: value.begin, lte: value.end)
        end
      else
        term(value)
      end
    end

    alias_method :=~, :===

    def >(value)
      range(gt: value)
    end

    def >=(value)
      range(gte: value)
    end

    def <(value)
      range(lt: value)
    end

    def <=(value)
      range(lte: value)
    end
  end
end
