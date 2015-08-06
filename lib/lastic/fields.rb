module Lastic
  class Field
    attr_reader :name
    
    def initialize(*names)
      @name = names.join('.')
    end

    def ==(other)
      other.is_a?(Field) && name == other.name
    end

    def to_s
      name
    end

    include Clauses

    def nested(path = nil)
      NestedField.new(name, path)
    end
  end

  class NestedField
    attr_reader :name, :path

    def initialize(name, path = nil)
      path ||= guess_path(name)
      validate_path(name, path)
      @name, @path = name.to_s, path.to_s
    end

    def ==(other)
      other.is_a?(NestedField) && name == other.name && path == other.path
    end

    def to_s
      name
    end

    include Clauses

    private

    def guess_path(name)
      name.to_s.split('.').tap{|c|
        c.count < 2 and fail(ArgumentError, "Seems not nested field name: #{name}")
      }[0..-2].join('.')
    end

    def validate_path(name, path)
      pc = path.to_s.split('.')
      nc = name.to_s.split('.')
      nc.count > pc.count && nc[0...pc.count] == pc or
        fail(ArgumentError, "Path #{path} is not part of the field #{name}")
    end
  end

  class Fields
    attr_reader :fields
    
    def initialize(*names)
      @fields = names.map(&Field.method(:new))
    end

    def ==(other)
      other.is_a?(Fields) && fields == other.fields
    end

    def to_a
      fields.map(&:to_s)
    end
  end
end
