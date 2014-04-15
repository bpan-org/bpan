ENV['BPAN_TEST_DIR'] = 'test/checkout'
FileUtils.rm_rf(File.join(File.dirname(__FILE__), 'checkout'))
ENV['BPAN_TEST_REMOTE'] = File.expand_path(File.join(File.dirname(__FILE__), 'remote'))
ENV['RACK_ENV'] = 'test'

Bundler.require
require_relative '../bpan'
require 'test/unit'
require 'rack/test'


class BpanTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_root
    get '/'
    assert_equal 302, last_response.status
    assert_equal 'http://bpan.org', last_response.location
  end

  def test_post_nothing
    post '/', ''
    assert_equal 400, last_response.status
    assert_match 'Invalid JSON', last_response.body
  end

  def test_post_different_nothing
    post '/', '{}'
    assert_equal 400, last_response.status
    assert_match 'Invalid action', last_response.body
  end

  def test_post_bad_action
    post '/', '{"action":"invalid-action"}'
    assert_equal 400, last_response.status
    assert_match 'Invalid action', last_response.body
  end

  def test_star
    post '/', <<-END
    {
     "sender" : {
        "gravatar_id" : "cd56dcbe68e6bc9609442fa7f4b3f502",
        "html_url" : "https://github.com/foo-aocole",
        "url" : "https://api.github.com/users/foo-aocole",
        "avatar_url" : "https://avatars.githubusercontent.com/u/393591?",
        "login" : "foo-aocole"
     },
     "action" : "starred"
    }
    END
    assert_equal 200, last_response.status, "Wrong status, body was #{last_response.body}"
    assert_match 'Thanks for starring, foo-aocole', last_response.body
  end

  def test_tag
    post '/', <<-END
      {
         "repository" : {
            "clone_url" : "#{File.expand_path(File.join(File.dirname(__FILE__), 'package'))}",
            "name" : "bpan",
            "size" : 312,
            "owner" : {
               "login" : "bpan-org",
               "type" : "Organization"
            }
         },
         "ref" : "0.0.5",
         "master_branch" : "master",
         "ref_type" : "tag",
         "pusher_type" : "user",
         "description" : ""
      }
    END
    assert_equal 200, last_response.status, "Wrong status, body was #{last_response.body}"
    assert_match 'Thanks for pushing "Mister-Blonde" version "0.0.5"', last_response.body
  end

end
