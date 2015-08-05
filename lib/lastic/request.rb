module Lastic
  class Request
    attr_reader :query
    
    def initialize
    end

    def query_must!(clause)
      clause = coerce_query_clause(clause)
        
      @query = if @query
        @query.must(clause)
      else
        clause # not creating additional Bool wrapper
      end
      self
    end

    def query_should!(clause)
      clause = coerce_query_clause(clause)
      
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

    protected

    def coerce_query_clause(clause)
      Clause.coerce(clause).tap{|cl|
        cl.quariable? or
          fail(ArgumentError, "`#{clause.name}` can't be used in query")
      }
    end
  end
end
