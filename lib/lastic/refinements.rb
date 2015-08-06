module Lastic
  module StringifyKeys
    refine Hash do
      def stringify_keys
        map{|k, v| [k.to_s, v]}.to_h
      end
    end
  end
end
