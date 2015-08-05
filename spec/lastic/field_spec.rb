module Lastic
  describe Field do
    describe :initialize do
      it 'can take string' do
        expect(Field.new('authors.name').name).
          to eq 'authors.name'
      end

      it 'can take array array' do
        expect(Field.new(:authors, :name).name).
          to eq 'authors.name'
      end

      it 'has a shortcut' do
        expect(Lastic.field(:authors, :name)).
          to eq Field.new('authors.name')
      end
    end

    describe :nested do
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

  describe Fields do
    describe :initialize do
      it 'initializes several fields' do
        fields = Fields.new('authors.name', 'authors.nickname')
        expect(fields.fields.count).to eq 2
        expect(fields.fields.map(&:name)).to eq ['authors.name', 'authors.nickname']
      end
    end
  end
end
