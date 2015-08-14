module Lastic
  module StringifySymbolize
    refine Hash do
      def stringify_keys!
        keys.each do |key|
          self[key.to_s] = delete(key)
        end
        self
      end

      def stringify_keys
        dup.stringify_keys!
      end

      def symbolize_keys!
        keys.each do |key|
          self[key.to_sym] = delete(key)
        end
        self
      end

      def symbolize_keys
        dup.symbolize_keys!
      end
      end
  end
end
