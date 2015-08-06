module Lastic
  class Clause
    def Clause.coerce_hash(fields)
      fields.map{|field, value|
        if field.is_a?(Field) || field.is_a?(NestedField) || field.is_a?(Fields)
          field === value
        else
          Field.new(field) === value
        end
      }.inject(&:must)
    end

    def Clause.coerce(cl, scope = nil)
      case cl
      when ::Hash
        Clause.coerce_hash(cl)
      when Clause, nil
        cl
      else
        fail(ArgumentError, "Can't coerce #{cl.class} to query clause")
      end.tap{|res|
        if res
          case scope
          when nil
          when :query
            res.queriable? or fail(ArgumentError, "`#{res.name}` can't be used in query")
          when :filter
            res.filterable? or fail(ArgumentError, "`#{res.name}` can't be used in filter")
          else
            fail(ArgumentError, "Undefined coercion scope: #{scope.inspect}")
          end
        end
      }
    end

    def ==(other)
      self.class == other.class
    end

    def queriable?
      true
    end

    def filterable?
      true
    end

    def name
      self.class.name.sub(/.+::/, '').downcase
    end

    protected

    def coerce(other, scope = nil)
      Clause.coerce(other, scope)
    end
  end

  class SimpleClause < Clause
    attr_reader :field
    
    def initialize(field)
      @field = field
    end

    def ==(other)
      super && field == other.field
    end

    def to_h(context = {})
      if field.is_a?(NestedField)
        {'nested' => {'path' => field.path, (context[:mode] || :filter).to_s => {name => internal_to_h(context)}}}
      else
        {name => internal_to_h(context)}
      end
    end
  end

  class BinaryClause < SimpleClause
    attr_reader :operand
    
    def initialize(field, operand)
      super(field)
      @operand = operand
    end

    def ==(other)
      super && operand == other.operand
    end

    protected

    def internal_to_h(context = {})
      {field.to_s => operand}
    end
  end

  # Simple clauses
  class Term < BinaryClause  
  end

  class Terms < BinaryClause
    def initialize(field, *values)
      super(field, values.flatten)
    end
  end

  class Wildcard < BinaryClause
  end

  class Regexp < BinaryClause
    def initialize(field, regexp)
      super(field, regexp.to_s.gsub(/^\(\?-mix:(.+)\)$/, '\1'))
    end
  end

  class Exists < SimpleClause
    def queriable?
      false
    end

    protected
    
    def internal_to_h(context = {})
      {'field' => field.to_s}
    end
  end

  class Range < SimpleClause
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

    protected
    
    def internal_to_h(context = {})
      {field.to_s => range.map{|k,v| [k.to_s, v]}.to_h}
    end
  end

  # Composed clauses
  class Not < Clause
    attr_reader :argument

    def initialize(argument)
      @argument = argument
    end

    def ==(other)
      super && argument == other.argument
    end

    def queriable?
      false
    end

    def not
      argument
    end

    def to_h(context = {})
      {'not' => argument.to_h(context)}
    end
  end

  class And < Clause
    attr_reader :arguments
    
    def initialize(*arguments)
      @arguments = arguments.map(&method(:coerce))
    end

    def ==(other)
      super && arguments == other.arguments
    end

    def queriable?
      false
    end

    def and(clause)
      And.new(*arguments, clause)
    end

    def to_h(context = {})
      {'and' => arguments.map{|a| a.to_h(context)}}
    end
  end

  class Or < Clause
    attr_reader :arguments

    def initialize(*arguments)
      @arguments = arguments.map(&method(:coerce))
    end

    def ==(other)
      super && arguments == other.arguments
    end

    def queriable?
      false
    end

    def or(clause)
      Or.new(*arguments, clause)
    end

    def to_h(context = {})
      {'or' => arguments.map{|a| a.to_h(context)}}
    end
  end

  class Bool < Clause
    attr_reader :must_clauses, :should_clauses, :must_not_clauses

    def initialize(must: [], should: [], must_not: [])
      @must_clauses, @should_clauses, @must_not_clauses =
        must.map(&method(:coerce)),
        should.map(&method(:coerce)),
        must_not.map(&method(:coerce))
    end

    def ==(other)
      super &&
        must_clauses == other.must_clauses &&
        should_clauses == other.should_clauses &&
        must_not_clauses == other.must_not_clauses
    end

    def must(*others)
      Bool.new(must: [*must_clauses, *others], should: should_clauses, must_not: must_not_clauses)
    end

    def should(*others)
      Bool.new(must: must_clauses, should: [*should_clauses, *others], must_not: must_not_clauses)
    end

    def must_not(*others)
      Bool.new(must: must_clauses, should: should_clauses, must_not: [*must_not_clauses, *others])
    end

    def to_h(context = {})
      {'bool' => {
        'must' => must_clauses.map{|c| c.to_h(context)},
        'should' => should_clauses.map{|c| c.to_h(context)},
        'must_not' => must_not_clauses.map{|c| c.to_h(context)}
      }.reject{|k,v| v.empty?}}
    end
  end

  class Filtered < Clause
    attr_reader :query_clause, :filter_clause

    def initialize(query: nil, filter: nil)
      @query_clause, @filter_clause = coerce(query, :query), coerce(filter, :filter)
    end

    def filterable?
      false
    end

    def filter_and(other)
      Filtered.new(query: query_clause, filter: filter_clause ? And.new(filter_clause, other) : other)
    end

    alias_method :filter, :filter_and

    def filter_or(other)
      Filtered.new(query: query_clause, filter: filter_clause ? Or.new(filter_clause, other) : other)
    end

    def to_h(context = {})
      {'filtered' => {
        'query' => query_clause.to_h(context.merge(mode: :query)),
        'filter' => filter_clause.to_h(context.merge(mode: :filter))
        }
      }
    end
  end

  # Clause#{composition} methods
  module ClauseComposition
    # simple booleans
    def not
      Not.new(self)
    end

    alias_method :~, :not

    def and(clause)
      And.new(self, clause)
    end

    alias_method :&, :and

    def or(clause)
      Or.new(self, clause)
    end

    alias_method :|, :or

    # Bool filter
    def must(*others)
      Bool.new(must: [self, *others])
    end

    def should(*others)
      Bool.new(should: [self, *others])
    end

    def must_not(*others)
      Bool.new(must_not: [self, *others])
    end

    # filtered
    def filter(other)
      Filtered.new(query: self, filter: other)
    end

    alias_method :filter_and, :filter
    alias_method :filter_or, :filter
  end

  class Clause
    include ClauseComposition
  end

  # Field#{clause} methods
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
