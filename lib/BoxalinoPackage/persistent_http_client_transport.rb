require_relative('thrift')

require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'stringio'

module Thrift
  class PersistentHTTPClientTransport < BaseTransport

    def initialize(url, opts = {})
      @url = URI url
      @headers = {'Content-Type' => 'application/x-thrift'}
      @outbuf = Bytes.empty_byte_buffer
      @ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
      @http = Net::HTTP.new @url.host, @url.port
      @http.use_ssl = @url.scheme == 'https'
      @http.verify_mode = @ssl_verify_mode if @url.scheme == 'https'
      @times = []
    end

    def basic_auth(user, pwd)
      @authuser = user
      @authpwd = pwd
    end

    def open?; true end
    def read(sz); @inbuf.read sz end
    def write(buf); @outbuf << Bytes.force_binary_encoding(buf) end

    def add_headers(headers)
      @headers = @headers.merge(headers)
    end

    def flush
      time_then = Time.now
      post = Net::HTTP::Post.new @url.request_uri
      post.basic_auth @authuser, @authpwd
      resp = @http.request post, @outbuf
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
