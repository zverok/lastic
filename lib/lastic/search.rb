module Lastic
  class Search < Request
    attr_reader :client, :index, :type
    
    def initialize(client, index: nil, type: nil)
      require_es!
      
      @client, @index, @type = client, index, type

      super()
    end

    def perform
      Response.new(client.search(index: index, type: type, body: to_h))
    end

    private

    def require_es!
      require 'elasticsearch'
    rescue LoadError
      fail "You should include 'elasticsearch' to your Gemfile in order to use Search"
    end

    require_relative 'search/response'
  end
end
