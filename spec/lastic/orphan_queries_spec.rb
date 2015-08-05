module Lastic
  describe Query, 'without fields' do
    context :query_string do
      it 'is generated correctly' do
        expect(Query.query_string('this AND that')).
          to eq(QueryString.new(nil, 'this AND that'))
      end
    end

    context :simple_query_string do
    end

    # TODO: and so on
  end
end
