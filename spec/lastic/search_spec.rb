module Lastic
  include Clauses
  
  describe Search do
    it 'is created by server & index & type' do
      search = Search.new
      expect(search.host).to be_nil
      expect(search.index).to be_nil
      expect(search.type).to be_nil
      expect(search.options).to eq( {} )
      expect(search.client).to be_kind_of(Elasticsearch::Transport::Client)

      search = Search.new host: 'http://api.company.com:9200', index: 'main', type: 'mention'
      expect(search.host).to eq 'http://api.company.com:9200'
      expect(search.index).to eq 'main'
      expect(search.type).to eq 'mention'
      expect(search.client).to be_kind_of(Elasticsearch::Transport::Client)
    end

    it 'is descendant of request and posesses its properties' do
      search = Search.new.
        query(title: 'Slaughterhouse Five').
        filter(Lastic.field('author.name').nested => 'Vonnegut').
        sort(:price)

      expect(search).to be_a(Search)
      expect(search).to be_kind_of(Request)
      expect(search.to_h).to include('query', 'sort')
    end

    describe :perform do
      it 'should call ElasticSearch' do
        search = Search.new(index: 'main').
          query(title: 'Slaughterhouse Five').
          filter(Lastic.field('author.name').nested => 'Vonnegut').
          sort(:price)

        expect(search.client).to receive(:search).
          with(body: search.to_h, index: search.index, type: search.type).
          and_return({}.to_json)

        search.perform
      end

      context 'response processing' do
        let(:sample_response){
          {
            'hits' => {
              'total' => 10,
              'hits' => [
                {'id' => 1, 'title' => 'foo'},
                {'id' => 1, 'title' => 'bar'}
              ]
            }
          }
        }
        let(:search){
          Search.new(index: 'main').
          query(title: 'Slaughterhouse Five').
          filter(Lastic.field('author.name').nested => 'Vonnegut').
          sort(:price)
        }
        before{
          expect(search.client).to receive(:search).
            with(body: search.to_h, index: search.index, type: search.type).
            and_return(sample_response.to_json)
        }
        let(:response){search.perform}
        subject{response}
        
        its(:raw){should be_kind_of(Hashie::Mash)}
        its(:raw){should == sample_response}
        its(:count){should == sample_response['hits']['total']}
        its(:to_a){should == sample_response['hits']['hits']}
      end
    end

    describe :count do
    end
  end
end
