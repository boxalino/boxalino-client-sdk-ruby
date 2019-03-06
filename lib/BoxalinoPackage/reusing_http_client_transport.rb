require_relative('thrift')
#require_relative('lib_httpclient/httpclient')
require 'httpclient'

require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'stringio'

module Thrift
  class ReusingHttpClientTransport < BaseTransport

    def initialize(url, client)
      @url = url
      @headers = {'Content-Type' => 'application/x-thrift'}
      @outbuf = Bytes.empty_byte_buffer
      @client = client
    end

    def basic_auth(user, pwd)
      @client.set_auth(@url, user, pwd)
    end

    def set_profile(profileId)
      @headers.store("X-BX-PROFILEID", profileId)
    end

    def open?; true end
    def read(sz); @inbuf.read sz end
    def write(buf); @outbuf << Bytes.force_binary_encoding(buf) end

    def add_headers(headers)
      @headers = @headers.merge(headers)
    end

    def flush
      resp = @client.post(@url, @outbuf, @headers)
      data = resp.body
      data = Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
      @outbuf = Bytes.empty_byte_buffer
    end

  end
end
