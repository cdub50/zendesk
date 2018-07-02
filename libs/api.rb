# encoding: utf-8
require 'rest_client'
require 'yaml'
require 'json'

# API class used for get,put,post,delete using rest client
class Api
  def initialize
    config = YAML.safe_load(File.open(File.expand_path('../../configs/config.yml', __FILE__)))
    @base_url = "#{config['environment']}"
  end

  def get(url, header)
    RestClient.get("#{@base_url}/#{url}", header) { |response| response }
  end

  def post(url, body, header)
    RestClient.post("#{@base_url}/#{url}", body, header) { |response| response }
  end

  def put(url, body, header)
    RestClient.put("#{@base_url}/#{url}", body, header) { |response| response }
  end

  def delete(url, header)
    RestClient.delete("#{@base_url}/#{url}", header) { |response| response }
  end
end
