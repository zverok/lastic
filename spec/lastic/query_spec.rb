module Lastic
  describe Query do
    describe :initialize do
    end

    context 'updating' do
      subject(:query){Query.new}
      
      describe :must do
        it 'should add must clauses to query' do
          expect(query.must_clauses).to be_empty
          q1 = query.must(field(:title).term('test'))
          expect(q1.must_clauses).
            to eq [field(:title).term('test')]

          q2 = query.must(year: 2014..2015)
          expect(q1.must_clauses).
            to eq [
              field(:title).term('test'),
              field(:year).range(gte: 2014, lte: 2015)
            ]
        end
        
        it 'should raise on non-queriable clause' do
          and_clause = 
        end
      end

      describe :should do
      end

      describe :must_not do
      end

      describe :filter do
        context 'when non-filterable clause' do
        end
      end

      describe :filter_or do
      end
    end

    describe :to_h do
      context 'when empty' do
      end

      context 'when non-empty' do
      end
    end
  end
end
