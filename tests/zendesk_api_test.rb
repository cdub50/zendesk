# encoding: utf-8
require_relative '../libs/helpers/test_helper'

class TestZendeskApi < Minitest::Test
  parallelize_me!
  
  def setup
  	config = YAML.load(File.open(File.expand_path('../../configs/config.yml', __FILE__)))
    @token = config['api_token']
    @user = config['user']
    @auth = Base64.strict_encode64("#{@user}/token:#{@token}")
    @api = Api.new
    @header = {
      authorization: 'Basic ' + @auth,
      content_type: 'application/json',
      accept: 'application/json'
    }
    @header_post = {
      authorization: 'Basic ' + @auth,
      content_type: 'application/x-www-form-urlencoded',
      accept: 'application/json'
    }
  end

  def create_ticket
    body = {
      'ticket': {
        'subject': 'Test All the Things!', 
        'comment': { 
          'body': 'Lets test all the things.' 
        }
      }
    }
    resp = @api.post('tickets.json', body, @header_post)
    return resp
  end

  def test_authentication
  	resp = @api.get('users.json', @header)
  	assert resp.code == 200, "Authentication failed. " + resp
    data = JSON.parse(resp)
    users = []
    data['users'].each do |user|
      users << user if user['name'] == 'chris wardall'
    end
    refute_empty users, 'Your username did not match.' 
  end

  def test_create_a_ticket
    resp = create_ticket
    data = JSON.parse(resp)
    assert resp.code == 201
    assert data['ticket']['subject'] == 'Test All the Things!'
  end

  def test_add_comment_to_ticket
    resp = create_ticket
    data = JSON.parse(resp)
    assert resp.code == 201
    id = data['ticket']['id']
    body = {
      'ticket': { 
        'comment': { 
          'body': 'Lets test all the things again!' 
        }
      }
    }
    resp = @api.put("tickets/#{id}.json", body, @header_post)
    assert resp.code == 200, "Update to ticket failed " + resp
    data = JSON.parse(resp)
    events = []
    data['audit']['events'].each do |e|
      events << e['body'] if e['body'] == 'Lets test all the things again!'
    end
    refute_empty events[0], 'Comment did not match our string.'
  end
  
  def test_list_all_tickets
    total = JSON.parse(@api.get("tickets.json?sort_by=created_at", @header))['count']
    tickets = []
    page = 0
    loop do 
      page +=1
      resp = @api.get("tickets.json?page=#{page}&sort_by=created_at", @header)
      data = JSON.parse(resp)
      total = data['count']
      tickets << data['tickets']
      break if data['next_page'].nil?
    end
    assert total == tickets.flatten!.count
  end

  def test_delete_ticket
    resp = create_ticket
    data = JSON.parse(resp)
    assert resp.code == 201
    id = data['ticket']['id']
    resp = @api.delete("tickets/#{id}.json", @header)
    assert resp.code == 204, 'Response was not a 204. ' + resp
    del_ticket = @api.get('deleted_tickets.json', @header)
    data = JSON.parse (del_ticket)
    ticket = []
    data['deleted_tickets'].each do |del_ticket|
      ticket << del_ticket['id'].to_i if del_ticket['id'].to_i == id.to_i
    end
    assert ticket[0] == id.to_i
  end
end
