require_relative('thrift')
#require_relative('lib_httpclient/httpclient')
require 'httpclient'

require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'stringio'

module Thrift
  class ReusingHTTPClientTransport < BaseTransport

    def initialize(url, opts = {})
      @url = url
      @headers = {'Content-Type' => 'application/x-thrift'}
      @outbuf = Bytes.empty_byte_buffer
      @times = []
      @client = HTTPClient.new
    end

    def basic_auth(user, pwd)
      @client.set_auth(@url, user, pwd)
    end

    def open?; true end
    def read(sz); @inbuf.read sz end
    def write(buf); @outbuf << Bytes.force_binary_encoding(buf) end

    def add_headers(headers)
      @headers = @headers.merge(headers)
    end

    def flush
      time_then = Time.now
      resp = @client.post(@url, @outbuf)
      data = resp.body
      data = Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
      @outbuf = Bytes.empty_byte_buffer
      took = (Time.now - time_then) * 1000
      @times.push took
    end
    
    def times
      return @times
    end
    
  end
end
