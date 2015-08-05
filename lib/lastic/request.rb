module Lastic
  class Request
    attr_reader :query
    
    def initialize
      @query = nil
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

    def query_must(clause)
      dup.query_must!(clause)
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
