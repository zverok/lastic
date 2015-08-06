module Lastic
  module Clauses
    class Simple < Base
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

    class MultiField < Base
      attr_reader :fields
      
      def initialize(fields)
        @fields = coerce_fields(fields)
      end

      def ==(other)
        super && fields == other.fields
      end

      def to_h
        {name => {'fields' => fields.to_a, 'query' => string}.reject{|k, v| v.empty?}}
      end

      private

      def coerce_fields(fields)
        case fields
        when Field, NestedField
          Fields.new(fields)
        when Fields
          fields
        when nil
          Fields.new
        else
          fail(ArgumentError, "Can't coerce #{fields.class} to Fields")
        end
      end
    end

    class Binary < Simple
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
      def initialize(field, regexp)
        super(field, regexp.to_s.gsub(/^\(\?-mix:(.+)\)$/, '\1'))
      end
    end

    class Exists < Simple
      def queriable?
        false
      end

      protected
      
      def internal_to_h(context = {})
        {'field' => field.to_s}
      end
    end

    class Range < Simple
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

    class QueryStringBase < MultiField
      attr_reader :string, :options
      
      def initialize(fields, string, **options)
        super(fields)
        @string, @options = string, options
      end

      def filterable?
        false
      end
    end
    
    class QueryString < QueryStringBase
    end

    class SimpleQueryString < QueryStringBase
    end

    module FromField
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

      def query_string(str, **options)
        QueryString.new(self, str, **options)
      end

      def simple_query_string(str, **options)
        SimpleQueryString.new(self, str, **options)
      end

      # shortcuts -------------------------
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

    module FromFields
      def query_string(str, **options)
        QueryString.new(self, str, **options)
      end

      def simple_query_string(str, **options)
        SimpleQueryString.new(self, str, **options)
      end
    end

    class ::Lastic::Field
      include Clauses::FromField
    end

    class ::Lastic::NestedField
      include Clauses::FromField
    end

    class ::Lastic::Fields
      include Clauses::FromFields
    end
  end
end
