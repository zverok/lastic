module Lastic
  include Clauses

  describe Clauses, 'coercion' do
    it 'coerces field name and operation' do
      expect(Clauses.coerce(length: (1..10))).
        to eq Range.new(Field.new('length'), gte: 1, lte: 10)

      expect(Clauses.coerce(length: (1..10), name: 'John')).
        to eq Bool.new(must: [
          Range.new(Field.new('length'), gte: 1, lte: 10),
          Term.new(Field.new('name'), 'John')
          ])
    end

    it 'coerces fields and nested fields' do
      expect(Clauses.coerce(Lastic.field(:length) => (1..10))).
        to eq Range.new(Field.new('length'), gte: 1, lte: 10)

      expect(Clauses.coerce(Lastic.field('body.length').nested => (1..10))).
        to eq Range.new(NestedField.new('body.length', 'body'), gte: 1, lte: 10)
    end
  end
end
