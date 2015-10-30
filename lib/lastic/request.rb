module Lastic
  class Request
    def initialize
      @aggs = Hashie::Mash.new
    end

    def ==(other)
      other.is_a?(Request) && other.to_h == to_h
    end

    # Quering ----------------------------------------------------------
    def query_must!(*clauses)
      @query = [@query, *clauses.map{|c| Clauses.coerce(c, :query)}].
        compact.inject(&:must)

      self
    end

    alias_method :query!, :query_must!

    def query_should!(*clauses)
      clauses = [@query, *clauses.map{|c| Clauses.coerce(c, :query)}].compact

      @query = if clauses.count == 1
        clauses.first.should # always marks itself as a should
      else
        clauses.inject(:should)
      end

      self
    end

    def query_must_not!(*clauses)
      clauses = clauses.map{|c| Clauses.coerce(c, :query)}
      @query = Clauses::Bool.new(must: [@query].compact, must_not: clauses)

      self
    end

    def raw_query
      @query
    end

    # Filtering --------------------------------------------------------
    def filter_and!(*clauses)
      @filter = [@filter, *clauses.map{|c| Clauses.coerce(c, :filter)}].
        compact.inject(&:and)

      self
    end

    #alias_method :filter!, :filter_and!

    def filter_or!(*clauses)
      @filter = [@filter, *clauses.map{|c| Clauses.coerce(c, :filter)}].
        compact.inject(&:or)

      self
    end

    def filter_must!(*clauses)
      @filter = [@filter, *clauses.map{|c| Clauses.coerce(c, :filter)}].
        compact.inject(&:must)

      self
    end

    def filter_should!(*clauses)
      clauses = clauses.map{|c| Clauses.coerce(c, :filter)}
      @filter = Clauses::Bool.new(must: [@filter].compact, should: clauses)

      self
    end

    def filter_must_not!(*clauses)
      clauses = clauses.map{|c| Clauses.coerce(c, :filter)}
      @filter = Clauses::Bool.new(must: [@filter].compact, must_not: clauses)

      self
    end

    alias_method :filter!, :filter_must!

    # Ordering ---------------------------------------------------------
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-sort.html
    # sort(:me, you: :desc, Lastic.field(:price).desc.avg)
    def sort!(*fields)
      @sort = fields.map(&SortableField.method(:coerce))
      self
    end

    # Limiting ---------------------------------------------------------
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
    def from!(from, size = nil)
      from, size = from.begin, (from.end-from.begin) if from.is_a?(::Range)
      @from = from
      @size = size if size
      self
    end

    # Aggregations -----------------------------------------------------
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
    def aggregations!(*as)
      ahash = as.last.is_a?(Hash) ? as.pop : {}

      # FIXME: too naive anti-collision naming
      ahash.merge!(as.map{|a| ["#{a.name}_#{rand(100)}", a]}.to_h)
      
      ahash.each do |k, v|
        v.kind_of?(Aggs::Base) or
          fail(TypeError, "#{k}: not suitable type for aggregation: #{v.class}")
      end

      @aggs.merge!(ahash)
      self
    end

    alias_method :aggs!, :aggregations!

    # Non-bang versions ------------------------------------------------
    def query(*arg)
      return filtered_query if arg.empty?
      dup.query!(*arg)
    end

    def query_must(*clauses)
      dup.query_must!(*clauses)
    end

    def query_should(*clauses)
      dup.query_should!(*clauses)
    end

    def query_must_not(*clauses)
      dup.query_must_not!(*clauses)
    end

    def filter(*arg)
      return @filter if arg.empty?
      dup.filter!(*arg)
    end

    def filter_and(*clauses)
      dup.filter_and!(*clauses)
    end

    def filter_or(*clauses)
      dup.filter_or!(*clauses)
    end

    def filter_should(*clauses)
      dup.filter_should!(*clauses)
    end

    def filter_must_not(*clauses)
      dup.filter_must_not!(*clauses)
    end

    def sort(*arg)
      return @sort if arg.empty?
      dup.sort!(*arg)
    end

    def from(*arg)
      return @from if arg.empty?
      dup.from!(*arg)
    end

    def size(*arg)
      return @size if arg.empty?
      dup.size!(*arg)
    end

    def aggregations(*arg)
      return @aggs if arg.empty?
      dup.aggregations!(*arg)
    end

    alias_method :aggs, :aggregations

    # Dumping ----------------------------------------------------------
    def to_h
      {
        'query' => (query ? query.to_h : {'match_all' => {}}),
        'sort' => sort && sort.map(&:to_h),
        'from' => from,
        'size' => size,
        'aggregations' => aggregations.map{|k, v| [k, v.to_h]}.to_h
      }.reject{|k, v| v.nil? || v.respond_to?(:empty?) && v.empty?}
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
