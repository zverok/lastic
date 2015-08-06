module Lastic
  describe SortableField do
    let(:field){Lastic.field(:title)}
    
    it 'can be obtained from field' do
      expect(field.asc).to eq SortableField.new(field, order: 'asc')
      expect(field.desc).to eq SortableField.new(field, order: 'desc')
    end

    describe :to_h do
      subject(:sortable){SortableField.new(field, order: 'asc')}

      its(:to_h){
        should == {'title' => {'order' => 'asc'}}
      }
    end
  end
end
