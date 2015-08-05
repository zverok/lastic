module Lastic
  describe Field, 'conversion to clause' do
    let(:source){Field.new(:title)}
    
    context 'simple operators' do
      it 'should do the clauses!' do
        expect(source.term('Alice In Wonderland')).
          to eq Term.new(source, 'Alice In Wonderland')

        expect(source.terms('Alice In Wonderland', 'Slaughterhouse Five')).
          to eq Terms.new(source, ['Alice In Wonderland', 'Slaughterhouse Five'])

        expect(source.wildcard('Alice*')).
          to eq Wildcard.new(source, 'Alice*')

        expect(source.exists).
          to eq Exists.new(source)

        expect(source.regexp(/[Aa]l?/)).
          to eq Regexp.new(source, /[Aa]l?/)

        expect(source.range(gte: 1, lte: 2)).
          to eq Range.new(source, gte: 1, lte: 2)
      end
    end

    context 'operators shortcuts' do
      it 'works with comparison' do
        expect(source === 'Alice In Wonderland').
          to eq Term.new(source, 'Alice In Wonderland')

        expect(source === ['Alice In Wonderland', 'Slaughterhouse Five']).
          to eq Terms.new(source, ['Alice In Wonderland', 'Slaughterhouse Five'])
        
        expect(source === /[Aa]l?/).
          to eq Regexp.new(source, /[Aa]l?/)

        expect(source === (1..2)).
          to eq Range.new(source, gte: 1, lte: 2)

        expect(source === (1...2)).
          to eq Range.new(source, gte: 1, lt: 2)
      end

      it 'works with fancy operators' do
        expect(source =~ /[Aa]l?/).
          to eq Regexp.new(source, /[Aa]l?/)

        expect(source > 1).
          to eq Range.new(source, gt: 1)

        expect(source >= 1).
          to eq Range.new(source, gte: 1)

        expect(source < 1).
          to eq Range.new(source, lt: 1)

        expect(source <= 1).
          to eq Range.new(source, lte: 1)

        expect((source > 1) < 2).
          to eq Range.new(source, gt: 1, lt: 2)
      end
    end

    context 'clause coercion' do
      it 'coerces field name and operation' do
        expect(Clause.coerce(length: (1..10))).
          to eq Range.new(Field.new('length'), gte: 1, lte: 10)

        expect(Clause.coerce(length: (1..10), name: 'John')).
          to eq Bool.new(must: [
            Range.new(Field.new('length'), gte: 1, lte: 10),
            Term.new(Field.new('name'), 'John')
            ])
      end

      it 'coerces fields and nested fields' do
        expect(Clause.coerce(Lastic.field(:length) => (1..10))).
          to eq Range.new(Field.new('length'), gte: 1, lte: 10)

        expect(Clause.coerce(Lastic.field('body.length').nested => (1..10))).
          to eq Range.new(NestedField.new('body.length', 'body'), gte: 1, lte: 10)
      end
    end
  end
end
