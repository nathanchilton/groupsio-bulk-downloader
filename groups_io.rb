# frozen_string_literal: true

require_relative "./rest_request.rb"
require "json"
require "pry"

class GroupsIO
  def initialize(username, password)
    @base_url = "https://groups.io/api/"
    login(username, password)
  end

  def login(username, password)
    route = "v1/login"
    parameter_array = []
    parameter_array << ["email", username]
    parameter_array << ["password", password]
    parameter_array << %w[api_key nonce]

    route += "?" + URI.encode_www_form(parameter_array)

    url = @base_url + route
    response = RestRequest.new.http_post(url)
    unless response.code == "200"
      raise "Authentication failed.\n\tCode:\t#{response.code}\n\tBody:\t#{response.body}"
    end

    all_cookies = response.get_fields("set-cookie")
    cookies_array = []
    all_cookies.each do |cookie|
      cookies_array.push(cookie.split("; ")[0])
    end
    @cookies = cookies_array.join("; ")

    @user_object = JSON.parse(response.body)["user"]
  end

  def user
    @user_object
  end

  def subscriptions
    @user_object["subscriptions"]
  end

  def get_albums(group_id)
    route = "v1/getalbums"
    albums = []

    parameter_array = []
    parameter_array << ["group_id", group_id]

    route += "?" + URI.encode_www_form(parameter_array)

    url = @base_url + route
    response = RestRequest.new(cookies: @cookies).http_get(url)

    if response.code == "200"

      body = JSON.parse(response.body)

      albums += body["data"]
      while body["has_more"]
        url = @base_url + route + "&page_token=#{body["next_page_token"]}"
        response = RestRequest.new(cookies: @cookies).http_get(url)
        body = JSON.parse(response.body)
        binding.pry unless body["data"]
        albums += body["data"]
      end
    end
    albums
  end

  def get_photos(group_id, album_id)
    route = "v1/getphotos"
    photos = []

    parameter_array = []
    parameter_array << ["group_id", group_id]
    parameter_array << ["album_id", album_id]

    route += "?" + URI.encode_www_form(parameter_array)

    url = @base_url + route
    response = RestRequest.new(cookies: @cookies).http_get(url)

    if response.code == "200"

      body = JSON.parse(response.body)

      photos += body["data"]
      while body["has_more"]
        url = @base_url + route + "&page_token=#{body["next_page_token"]}"
        response = RestRequest.new(cookies: @cookies).http_get(url)
        body = JSON.parse(response.body)
        binding.pry unless body["data"]
        photos += body["data"]
      end
    end
    photos
  end
end
