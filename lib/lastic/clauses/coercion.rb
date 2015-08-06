module Lastic
  module Clauses
    module Coercion
      def coerce_hash(fields)
        fields.map{|field, value|
          if field.is_a?(Field) || field.is_a?(NestedField) || field.is_a?(Fields)
            field === value
          else
            Field.new(field) === value
          end
        }.inject(&:must)
      end

      def coerce(cl, scope = nil)
        case cl
        when ::Hash
          coerce_hash(cl)
        when Base, nil
          cl
        else
          fail(ArgumentError, "Can't coerce #{cl.class} to query clause")
        end.tap{|res| check_scope!(res, scope) if res && scope}
      end

      private

      def check_scope!(clause, scope)
        case scope
        when nil
          # do nothing
        when :query
          clause.queriable? or fail(ArgumentError, "`#{clause.name}` can't be used in query")
        when :filter
          clause.filterable? or fail(ArgumentError, "`#{clause.name}` can't be used in filter")
        else
          fail(ArgumentError, "Undefined coercion scope: #{scope.inspect}")
        end
      end
    end

    extend Coercion
  end
end
  
