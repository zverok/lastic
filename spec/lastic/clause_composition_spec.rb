module Lastic
  describe Clause, 'composition' do
    let(:field){Field.new(:title)}
    let(:clause){field.term('Vonnegut')}
    
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
    end

    context 'or' do
    end

    context 'filter' do
    end
  end
end
