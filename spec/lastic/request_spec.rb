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

      describe :query_must_not! do
      end

      describe :filter_and! do
        it 'attaches filter to previous' do
          expect(request.filter).to be_nil

          request.filter_and!(Lastic.field(:title).exists)
          expect(request.filter).to eq Exists.new(Lastic.field(:title))

          request.filter_and!(title: /test/)
          expect(request.filter).
            to eq And.new(
              Exists.new(Lastic.field(:title)),
              Regexp.new(Lastic.field(:title), 'test')
            )
        end

        it 'wraps request\'s query' do
          request.filter_and!(Lastic.field(:title).exists)
          expect(request.query).to eq Filtered.new(filter: Exists.new(Lastic.field(:title)))
        end

        it 'wraps correctly even after long query/filter chains' do
        end

        it 'raises on non-filterable clause' do
          expect{
            request.filter_and!(Lastic.field(:title).term('test').filter(title: /test/))
          }.to raise_error(ArgumentError, /be used in filter/)
        end
      end

      describe :filter_or! do
        it 'attaches filter to previous' do
        end
      end

      describe :sort do
      end

      describe :from! do
        it 'updates offset' do
          expect(request.from).to be_nil
          request.from!(20)
          expect(request.from).to eq 20
        end

        it 'updates limit, if provided' do
          expect(request.size).to be_nil
          request.from!(20, 100)
          expect(request.from).to eq 20
          expect(request.size).to eq 100
        end

        it 'works with range' do
          expect(request.size).to be_nil
          request.from!(20...40)
          expect(request.from).to eq 20
          expect(request.size).to eq 20
        end
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
      subject(:request){Request.new}
      
      it 'dumps query' do
        request.query!(title: 'Test')
        
        expect(request.to_h).
          to eq( 'query' => request.query.to_h )
      end

      it 'correctly dumps nested queries and filters' do
        request.query!(
          Lastic.field('author.name').nested.term('Vonnegut').
            filter(Lastic.field('author.dead').nested => true)
        ).filter!(
          Lastic.field('author.books.count').nested('author') => (30..100)
        )
        expect(request.to_h).to eq(
          'query' => {
            'filtered' => {
              'query' => {
                'filtered' => {
                  'query' => {
                    'nested' => {
                      'path' => 'author',
                      'query' => {
                        'term' => {
                          'author.name' => 'Vonnegut'
                        }
                      }
                    }
                  },
                  'filter' => {
                    'nested' => {
                      'path' => 'author',
                      'filter' => {
                        'term' => {
                          'author.dead' => true
                        }
                      }
                    }
                  }
                }
              },
              'filter' => {
                'nested' => {
                  'path' => 'author',
                  'filter' => {
                    'range' => {
                      'author.books.count' => {
                        'gte' => 30,
                        'lte' => 100
                      }
                    }
                  }
                }
              }
            }
          }
        )
      end

      it 'dumps sort' do
      end

      it 'dumps from/size' do
      end
    end
  end
end
