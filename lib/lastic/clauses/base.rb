module Lastic
  module Clauses
    class Base
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
        self.class.name.sub(/.+::/, '').gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      def to_h
        fail NotImplementedError, "#to_h was not redefined for `#{name}`"
      end

      protected

      def coerce(other, scope = nil)
        Clauses.coerce(other, scope)
      end
    end
  end
end
