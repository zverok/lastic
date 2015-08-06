module Lastic
  include Clauses
  
  describe Clauses::FromFields do
    let(:source){Fields.new(:title, :body)}

    context 'query strings' do
      it 'works' do
        expect(source.query_string('test AND me')).
          to eq(QueryString.new(source, 'test AND me'))

        expect(source.simple_query_string('test AND me')).
          to eq(SimpleQueryString.new(source, 'test AND me'))
      end
    end
  end
end
