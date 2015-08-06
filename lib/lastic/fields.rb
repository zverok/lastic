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

  class SortableField
    attr_reader :field, :options

    using StringifyKeys
    
    def initialize(field, **options)
      @field, @options = field, options
    end

    def ==(other)
      other.is_a?(SortableField) && field == other.field && options == other.options
    end

    def to_h
      {field.to_s => options.stringify_keys}
    end

    def self.coerce(field)
      case field
      when SortableField
        field
      when Field
        new(field)
      else
        new(Field.new(field))
      end
    end

    module FromField
      def asc
        SortableField.new(self, order: 'asc')
      end

      def desc
        SortableField.new(self, order: 'desc')
      end
    end
  end

  class Field
    include SortableField::FromField
  end
end
