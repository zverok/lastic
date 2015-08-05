module Lastic
  describe Clause, 'composition' do
    let(:field){Field.new(:title)}
    let(:clause){field.term('Vonnegut')}
    let(:clause2){field.wildcard('Br?db?ry')}
    let(:clause3){field.regexp(/H.+nl.+n/)}
    
    context 'bool' do
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

    context 'filter' do
    end
  end
end
