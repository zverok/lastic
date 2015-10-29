module Lastic
  module Aggregations
    using StringifySymbolize

    class Base
      
      attr_reader :name, :options
      
      def initialize(name, **options)
        @name, @options = name.to_s, options.stringify_keys
      end

      def initialize_copy(other)
        @name, @options = other.name, other.options.dup
      end

      def to_h
        {name => options}
      end
    end

    class Bucket < Base
      def initialize(*)
        super
        @aggs = Hashie::Mash.new
      end

      def initialize_copy(other)
        super
        @aggs = other.aggs.dup
      end
      
      def aggs!(*as)
        ahash = as.last.is_a?(Hash) ? as.pop : {}

        # FIXME: too naive anti-collision naming
        ahash.merge!(as.map{|a| ["#{a.name}_#{rand(100)}", a]}.to_h)
        
        ahash.each do |k, v|
          v.kind_of?(Base) or
            fail(TypeError, "#{k}: not suitable type for aggregation: #{v.class}")
        end

        @aggs.merge!(ahash)
        self
      end

      def aggs(*as)
        return @aggs if as.empty?

        dup.aggs!(*as)
      end

      def to_h
        if aggs.empty?
          super
        else
          super.merge('aggs' => aggs.map{|k, v| [k, v.to_h]}.to_h)
        end
      end
    end

    METRICS = %i[avg cardinality extended_stats geo_bounds geo_centroid
                max min percentiles percentile_ranks scripted_metric
                stats sum top_hits value_count]
    BUCKETS = %i[children date_histogram date_range filter filters
                geo_distance geohash_grid global histogram ip_range
                missing nested range reverse_nested sampler
                significant_terms terms]
    
    class << self
      METRICS.each do |sym|
        define_method(sym){|**opts|
          Base.new(sym, opts)
        }
      end

      BUCKETS.each do |sym|
        define_method(sym){|**opts|
          Bucket.new(sym, opts)
        }
      end
    end
  end

  Aggs = Aggregations
end
