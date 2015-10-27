require 'lastic/aggregations'

module Lastic
  describe Aggregations do
    describe :creation do
      it 'accepts options' do
        agg = Aggregations.terms(field: 'platform.id')
        expect(agg).to be_a(Aggregations::Base)
        expect(agg.name).to eq 'terms'
        expect(agg.options).to eq('field' => 'platform.id')
      end
    end

    describe :aggs! do
      let(:agg){Aggregations.terms(field: 'platform.id')}
      
      it 'accepts named sub-aggs' do
        agg.aggs!(platforms: Aggs.top_hits)
        expect(agg.aggs).to include('platforms' => kind_of(Aggs::Base))
        expect(agg.aggs[:platforms]).to be_kind_of(Aggs::Base)
      end

      it 'validates sub-aggs type' do
        expect{agg.aggs!(platforms: 'platform.id')}.to raise_error(TypeError)
      end

      it 'accepts unnamed sub-aggs' do
        agg.aggs!(Aggs.top_hits)
        expect(agg.aggs.keys.first).to match /^top_hits_\d+$/
        expect(agg.aggs.values.first).to be_kind_of(Aggs::Base)
      end
    end

    describe :aggs do
      let(:agg){Aggregations.terms(field: 'platform.id')}

      it 'does no changes to source' do
        agg2 = agg.aggs(platforms: Aggs.top_hits)
        expect(agg.aggs).to be_empty
        expect(agg2.aggs).to include('platforms' => kind_of(Aggs::Base))
      end
    end

    describe :to_h do
      it 'converts plain agg' do
        agg = Aggs.terms(field: 'platform.id')
        expect(agg.to_h).to eq('terms' => {'field' => 'platform.id'})
      end

      it 'converts with sub-aggregations' do
        agg = Aggs.terms(field: 'platform.id').aggs(th: Aggs.top_hits)
        expect(agg.to_h).to eq(
          'terms' => {'field' => 'platform.id'},
          'aggs' => {'th' => {'top_hits' => {}}}
        )
      end
    end
  end
end
