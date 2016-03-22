module Lastic
  include Clauses

  describe Request do
    describe 'updating' do
      subject(:request){Request.new}

      describe :query_must! do
        it 'adds must clauses to query' do
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

        it 'raises on non-queriable clause' do
          expect{request.query_must!(Lastic.field(:title).exists)}.
            to raise_error(ArgumentError, /used in query/)
        end
      end

      describe :query_should! do
        it 'adds should clauses to query' do
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

          request.query_should!(Lastic.field(:name).term('Vonnegut'), Lastic.field(:name).term('Heinlein'))
          expect(request.query).
            to eq Bool.new(should: [
              Lastic.field(:title).term('test'),
              Lastic.field(:year).range(gte: 2014, lte: 2015),
              Lastic.field(:name).term('Vonnegut'),
              Lastic.field(:name).term('Heinlein')
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
          expect(request.filter).to be_nil

          request.filter_or!(Lastic.field(:title).exists)
          expect(request.filter).to eq Exists.new(Lastic.field(:title))

          request.filter_or!(title: /test/)
          expect(request.filter).
            to eq Or.new(
              Exists.new(Lastic.field(:title)),
              Regexp.new(Lastic.field(:title), 'test')
            )
        end
      end

      describe :sort! do
        it 'sets sort fields' do
          expect(request.sort).to be_nil
          request.sort!(:title, Lastic.field(:body).desc)
          expect(request.sort).
            to eq([
              SortableField.new(Field.new(:title)),
              SortableField.new(Field.new(:body), order: 'desc')
            ])
        end
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

      describe :size! do
        it 'updates size' do
          expect(request.size).to be_nil
          request.size!(100)
          expect(request.size).to eq 100
        end
      end

      describe :aggs! do
        it 'adds aggregations' do
          expect(request.aggs).to be_empty
          request.aggs!(platforms: Aggs.terms(field: 'platform.id'))
          expect(request.aggs.size).to eq 1
          expect(request.aggs[:platforms]).to be_kind_of(Aggs::Base)
        end
      end
    end

    describe 'non-bang methods' do
      let(:initial){Request.new}

      let!(:result){
        initial.
          query(title: 'Slaughterhouse Five').
          filter(author: 'Vonnegut').
          sort(:rating).
          from(10, 20)
      }

      describe 'initial' do
        subject{initial}

        its(:query){should be_nil}
        its(:filter){should be_nil}
        its(:sort){should be_nil}
        its(:from){should be_nil}
        its(:size){should be_nil}
      end

      describe 'produced' do
        subject{result}

        its(:raw_query){should == Term.new(Field.new('title'), 'Slaughterhouse Five')}
        its(:filter){should == Term.new(Field.new('author'), 'Vonnegut')}
        its(:sort){should == [SortableField.new(Field.new(:rating))]}
        its(:from){should == 10}
        its(:size){should == 20}
      end
    end

    describe :to_h do
      subject(:request){Request.new}

      context 'empty' do
        subject{request}
        its(:to_h){
          should == {'query' => {'match_all' => {}}}
        }
      end

      context 'simple' do
        subject{request.query(title: 'Test')}

        its(:to_h){should == {'query' => subject.query.to_h}}
      end

      context 'filtered only' do
        subject{request.filter(title: 'Test')}

        its(:to_h){should == {
          'query' => {
            'filtered' => {
              'filter' => subject.filter.to_h
            }
          }
        }}
      end

      context 'aggregations' do
        subject{request.aggs(platforms: Aggs.terms(field: 'platform.id'))}

        its(:to_h){should == {
          'query' => {'match_all' => {}},
          'aggregations' => {
            'platforms' => {
              'terms' => {'field' => 'platform.id'}
            }
          }
        }}
      end

      context 'deep nesting' do
        subject{
          request.query(
            Lastic.field('author.name').nested.term('Vonnegut').
              filter(Lastic.field('author.dead').nested => true)
          ).filter(
            Lastic.field('author.books.count').nested('author') => (30..100)
          )
        }

        # THAT'S how Lastic rules. Compare THIS ↓ and THAT ↑ which are equal
        its(:to_h){should == {
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
        }}
      end

      context 'sort' do
        subject{request.sort(Lastic.field(:title).desc)}
        its(:to_h){should == {
          'query' => {'match_all' => {}},
          'sort' => [{'title' => {'order' => 'desc'}}]
        }}
      end

      context 'from/size' do
        subject{request.from(10, 20)}
        its(:to_h){should == {
          'query' => {'match_all' => {}},
          'from' => 10,
          'size' => 20
        }}
      end

      context 'size' do
        subject{request.size(100)}
        its(:to_h){should == {
          'query' => {'match_all' => {}},
          'size' => 100
        }}
      end
    end
  end
end
