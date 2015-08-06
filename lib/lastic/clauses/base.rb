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
        self.class.name.sub(/.+::/, '').downcase
      end

      protected

      def coerce(other, scope = nil)
        Clauses.coerce(other, scope)
      end
    end
  end
end
