module Lastic
  class Search < Request
    attr_reader :host, :index, :type, :options

    attr_reader :client
    
    def initialize(host: nil, index: nil, type: nil, **options)
      require_es!
      
      @host, @index, @type, @options = host, index, type, options

      @client = Elasticsearch::Client.new(
        {host: host}.merge(options)
      )
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
