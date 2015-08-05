module Lastic
  describe Field, 'nesting' do
    let(:source){Field.new(:author, :name)}
    it 'works with implicit path' do
      expect(source.nested).to eq NestedField.new(source, 'author')
    end

    it 'works with explicit path' do
      expect(source.nested(:author)).to eq NestedField.new(source, 'author')
    end

    it 'fails on wrong path' do
      expect{Field.new(:title).nested}.to raise_error(ArgumentError)
      expect{source.nested(:catalog)}.to raise_error(ArgumentError)
    end

    it 'can produce clauses' do
      expect(source.nested.term('Vonnegut')).
        to eq Term.new(NestedField.new(source, 'author'), 'Vonnegut')
    end
  end
end
