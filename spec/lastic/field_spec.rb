module Lastic
  describe Clause do
    describe :initialize do
      context 'with string' do
        subject{Field.new('authors.name')}

        its(:name){should == 'authors.name'}
      end

      context 'with array' do
        subject{Field.new(:authors, :name)}

        its(:name){should == 'authors.name'}
      end
    end

    describe 'operations' do
      let(:source){Field.new(:title)}

      describe :term do
        subject{source.term('Alice In Wonderland')}
        it{should be_a(Clause)}
        its(:op){should == :term}
        its(:field){should == source}
        its(:value){should == 'Alice In Wonderland'}
        its(:to_h){should ==
          {'term' => 
            {'title' => 'Alice In Wonderland'}
          }
        }
      end

      describe :terms do
        subject{source.terms('Alice In Wonderland', 'Slaughterhouse Five')}
        it{should be_a(Clause)}
        its(:op){should == :terms}
        its(:field){should == source}
        its(:value){should == ['Alice In Wonderland', 'Slaughterhouse Five']}
        its(:to_h){should ==
          {'terms' => 
            {'title' => ['Alice In Wonderland', 'Slaughterhouse Five']}
          }
        }
      end

      describe :regexp do
      end

      describe :wildcard do
        subject{source.wildcard('Alice In Wonder*')}
        it{should be_a(Clause)}
        its(:op){should == :wildcard}
        its(:field){should == source}
        its(:value){should == 'Alice In Wonder*'}
        its(:to_h){should ==
          {'wildcard' => 
            {'title' => 'Alice In Wonder*'}
          }
        }
      end

      describe :range do
      end

      describe :simple_query_string do
      end

      describe :nested do
        context 'by default' do
        end

        context 'with argument' do
        end

        context 'argument validation' do
        end
      end

      describe :exists? do
      end

      describe :type do
      end
    end

    describe :=== do
      context 'when single value' do
      end

      context 'when array' do
      end

      context 'when range' do
      end

      context 'when regexp' do
      end
    end

    describe 'inequality' do
    end
  end
end
