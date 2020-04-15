# frozen_string_literal: true

require "json"
require "uri"
require "net/http"
require "openssl"

class RestRequest
  def initialize(authorization: nil, content_type: "application/json", cookies: nil)
    @authorization = authorization
    @content_type = content_type
    @cookies = cookies
  end

  def send_request(verb, path, body: nil)
    url = URI(path)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    case verb
    when :get
      request = Net::HTTP::Get.new(url)
    when :post
      request = Net::HTTP::Post.new(url)
    when :delete
      request = Net::HTTP::Delete.new(url)
    when :put
      request = Net::HTTP::Put.new(url)
    else
      raise "Invalid http verb specified: #{verb}!"
    end

    request["content-type"] = @content_type
    request["Authorization"] = @authorization if @authorization
    request["cache-control"] = "no-cache"
    request["Cookie"] = @cookies if @cookies

    request.body = body unless body.nil?
    http.request(request)
  end

  def http_get(path, body: nil)
    send_request(:get, path, body: body)
  end

  def http_post(path, body: nil)
    send_request(:post, path, body: body)
  end

  def http_put(path, body: nil)
    send_request(:put, path, body: body)
  end

  def http_delete(path)
    send_request(:delete, path)
  end
end
