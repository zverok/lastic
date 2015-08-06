module Lastic
  include Clauses
  
  describe Clauses, 'composition' do
    let(:field){Field.new(:title)}
    let(:clause){field.term('Vonnegut')}
    let(:clause2){field.wildcard('Br?db?ry')}
    let(:clause3){field.regexp(/H.+nl.+n/)}
    
    context 'bool' do
      it 'works with must, should, must_not' do
        expect(clause.must).to eq Bool.new(must: [clause])
        expect(clause.must(clause2)).to eq Bool.new(must: [clause, clause2])

        expect(clause.should).to eq Bool.new(should: [clause])
        expect(clause.should(clause2)).to eq Bool.new(should: [clause, clause2])

        expect(clause.must_not).to eq Bool.new(must_not: [clause])
        expect(clause.must_not(clause2)).to eq Bool.new(must_not: [clause, clause2])
      end

      it 'produces flat structures' do
        expect(clause.must.should(clause2)).to eq Bool.new(must: [clause], should: [clause2])
      end
    end

    context 'not' do
      it 'wraps any clause' do
        expect(clause.not).to eq Not.new(clause)
      end

      it 'unwraps on double not' do
        expect(clause.not.not).to eq clause
      end

      it 'allows to use shortcut' do
        expect(~clause).to eq Not.new(clause)
      end
    end

    context 'and' do
      it 'attaches clause to clause' do
        expect(clause.and(clause2)).to eq And.new(clause, clause2)
      end

      it 'produces flat structure on subsequent calls' do
        expect(clause.and(clause2).and(clause3)).
          to eq And.new(clause, clause2, clause3)
      end

      it 'allows to use shortcut' do
        expect(clause & clause2).to eq And.new(clause, clause2)
      end

      it 'coerces second clause' do
        expect(clause.and(title: 'Test')).to eq And.new(clause, Term.new(Field.new('title'), 'Test'))

        expect(clause.and(Lastic.field('author.name').nested => 'Test')).
          to eq And.new(clause, Term.new(NestedField.new('author.name', 'author'), 'Test'))
      end
    end

    context 'or' do
      it 'attaches clause to clause' do
        expect(clause.or(clause2)).to eq Or.new(clause, clause2)
      end

      it 'produces flat structure on subsequent calls' do
        expect(clause.or(clause2).or(clause3)).
          to eq Or.new(clause, clause2, clause3)
      end

      it 'allows to use shortcut' do
        expect(clause | clause2).to eq Or.new(clause, clause2)
      end
    end

    context 'filtered' do
      it 'composes!' do
        expect(clause.filter(clause2)).to eq Filtered.new(query: clause, filter: clause2)
      end

      it 'creates flat structure on subsequent' do
        expect(clause.filter(clause2).filter(clause3)).
          to eq Filtered.new(query: clause, filter: And.new(clause2, clause3))

        expect(clause.filter(clause2).filter_or(clause3)).
          to eq Filtered.new(query: clause, filter: Or.new(clause2, clause3))
      end

      it 'raises on non-queriable as a query' do
        expect{Lastic.field(:title).exists.filter(clause2)}.
          to raise_error(ArgumentError, /be used in query/)
      end

      it 'raises on non-filterable as a filter' do
      end
    end

    context 'query' do
    end
  end
end
