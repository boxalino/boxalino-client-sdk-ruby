require_relative('thrift')

require 'net/http'
#require 'net/http/persistent'
require 'net/https'
require 'openssl'
require 'uri'
require 'stringio'

module Thrift
  class PersistentHttpClientTransport < BaseTransport

    @timeout = 3000
    @ssl_verify_mode = nil
    def initialize(url, opts = {})
      @url = URI url
      @headers = {'Content-Type' => 'application/x-thrift'}
      @outbuf = Bytes.empty_byte_buffer
      @ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    def set_timeout(timeout)
      @timeout = timeout
    end

    def basic_auth(user, pwd)
      @authuser = user
      @authpwd = pwd
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
      post = Net::HTTP::Post.new(@url.request_uri, @headers)
      post.basic_auth @authuser, @authpwd
      resp = Net::HTTP.start(@url.host, @url.port, :use_ssl => @url.scheme == 'https', :verify_mode => @ssl_verify_mode, :connect_timeout => @timeout) do |http|
        http.request(post, @outbuf)
      end
      data = resp.body
      data = Bytes.force_binary_encoding(data)
      @inbuf = StringIO.new data
      @outbuf = Bytes.empty_byte_buffer
    end
    
  end
end
