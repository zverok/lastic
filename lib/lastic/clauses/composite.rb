module Lastic
  module Clauses
    class Not < Base
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

    class And < Base
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

    class Or < Base
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

    class Bool < Base
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

    class Filtered < Base
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

    module Composition
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

    class Base
      include Composition
    end
  end
end
