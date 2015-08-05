module Lastic
  describe Request do
    describe :initialize do
    end

    describe 'updating' do
      subject(:request){Request.new}

      describe :query_must! do
        it 'should add must clauses to query' do
          expect(request.query).to be_nil
          
          request.query_must!(Lastic.field(:title).term('test'))
          expect(request.query).
            to eq Lastic.field(:title).term('test')

          request.query_must!(year: 2014..2015)
          expect(request.query).
            to eq Bool.new(must: [
              Lastic.field(:title).term('test'),
              Lastic.field(:year).range(gte: 2014, lte: 2015)
            ])
        end
        
        it 'should raise on non-queriable clause' do
          expect{request.query_must!(Lastic.field(:title).exists)}.
            to raise_error(ArgumentError, /used in query/)
        end
      end

      describe :query_should! do
        it 'should add must clauses to query' do
          expect(request.query).to be_nil
          
          request.query_should!(Lastic.field(:title).term('test'))
          expect(request.query).
            to eq Bool.new(should: [Lastic.field(:title).term('test')])

          request.query_should!(year: 2014..2015)
          expect(request.query).
            to eq Bool.new(should: [
              Lastic.field(:title).term('test'),
              Lastic.field(:year).range(gte: 2014, lte: 2015)
            ])
        end
      end

      describe :query_must_not do
      end

      describe :filter do
      end

      describe :sort do
      end

      describe :from do
      end
    end

    describe 'non-bang methods' do
      subject(:request){Request.new}

      it 'should never change source, just produce duplicate' do
        other = request.query_must(test: 'me')
        expect(request.query).to be_nil
        expect(other.query).to eq Term.new(Field.new('test'), 'me')
      end
    end

    describe :to_h do
    end
  end
end
