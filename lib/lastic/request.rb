module Lastic
  class Request
    def initialize
    end

    def query_must!(clause)
      clause = Clauses.coerce(clause, :query)
        
      @query = if @query
        @query.must(clause)
      else
        clause # not creating additional Bool wrapper
      end
      self
    end

    alias_method :query!, :query_must!

    def query_should!(clause)
      clause = Clauses.coerce(clause, :query)
      
      @query = if @query
        @query.should(clause)
      else
        clause.should
      end
      self
    end

    def from!(from, size = nil)
      from, size = from.begin, (from.end-from.begin) if from.is_a?(::Range)
      @from = from
      @size = size if size
      self
    end

    def filter_and!(clause)
      clause = Clauses.coerce(clause, :filter)

      @filter = if @filter
        @filter.and(clause)
      else
        clause
      end
      self
    end

    alias_method :filter!, :filter_and!

    def filter_or!(clause)
      clause = Clauses.coerce(clause, :filter)
      
      @filter = if @filter
        @filter.or(clause)
      else
        clause
      end
      self
    end

    def query(*arg)
      return filtered_query if arg.empty?
      dup.query!(*arg)
    end

    def filter(*arg)
      return @filter if arg.empty?
      dup.filter!(*arg)
    end

    def from(*arg)
      return @from if arg.empty?
      dup.from!(*arg)
    end

    def size(*arg)
      return @size if arg.empty?
      dup.size!(*arg)
    end

    def query_must(clause)
      dup.query_must!(clause)
    end

    def query_should(clause)
      dup.query_should!(clause)
    end

    def to_h
      {
        'query' => query.to_h
      }
    end

    protected

    def filtered_query
      if @filter
        Clauses::Filtered.new(query: @query, filter: @filter)
      else
        @query
      end
    end
  end
end
