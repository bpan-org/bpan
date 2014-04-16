ENV['BPAN_TEST_DIR'] = 'test/checkout'

def reset_checkout
  FileUtils.rm_rf(File.join(File.dirname(__FILE__), 'checkout'))
end

ENV['BPAN_TEST_REMOTE'] = File.expand_path(File.join(File.dirname(__FILE__), 'remote'))

def reset_remote
  FileUtils.rm_rf(File.join(File.dirname(__FILE__), 'remote'))
  Git.open(File.expand_path(File.join(File.dirname(__FILE__), '..'))).checkout('test/remote')
end
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
    reset_remote
    reset_checkout
    get '/authors.json'
    authors = JSON.parse(last_response.body)
    assert_equal %w{aocole foo-aocole}, authors.collect{ |a| a['login'] }.sort

    post '/', <<-END
    {
     "sender" : {
        "gravatar_id" : "cd56dcbe68e6bc9609442fa7f4b3f502",
        "html_url" : "https://github.com/bar-aocole",
        "url" : "https://api.github.com/users/bar-aocole",
        "avatar_url" : "https://avatars.githubusercontent.com/u/393591?",
        "login" : "bar-aocole"
     },
     "action" : "starred"
    }
    END
    assert_equal 200, last_response.status, "Wrong status, body was #{last_response.body}"
    assert_match 'Thanks for starring, bar-aocole', last_response.body

    get '/authors.json'
    authors = JSON.parse(last_response.body)
    assert_equal %w{aocole bar-aocole foo-aocole}, authors.collect{ |a| a['login'] }.sort
    assert_equal(
    {
      "login" => "bar-aocole",
      "gravatar_id" => "cd56dcbe68e6bc9609442fa7f4b3f502",
      "html_url" => "https://github.com/bar-aocole",
      "url" => "https://api.github.com/users/bar-aocole",
      "avatar_url" => "https://avatars.githubusercontent.com/u/393591?"
    }, authors.detect{|a|a['login']=='bar-aocole'})
    reset_remote
  end

  def test_tag
    reset_remote
    reset_checkout
    get '/packages.json'
    packages = JSON.parse(last_response.body)
    assert_equal Hash.new, packages

    post '/', <<-END
      {
         "repository" : {
            "clone_url" : "#{File.expand_path(File.join(File.dirname(__FILE__), 'package'))}",
            "name" : "bpan",
            "size" : 312,
            "owner" : {
               "login" : "ingydotnet",
               "type" : "User"
            }
         },
         "ref" : "0.0.6",
         "master_branch" : "master",
         "ref_type" : "tag",
         "pusher_type" : "user",
         "description" : ""
      }
    END
    assert_equal 200, last_response.status, "Wrong status, body was #{last_response.body}"
    assert_equal 'Thanks for pushing "test-more" version "0.0.6", sha 88ace73562fae962b2bdfd3e29d7738a4c274bfd', last_response.body

    get '/packages.json'
    packages = JSON.parse(last_response.body)
    expected = {
      "test-more"=>"test-more/ingydotnet",
      "test-more/ingydotnet"=>["0.0.6"],
      "test-more/ingydotnet/0.0.6" => {
        "=meta"=>"0.0.1",
        "name"=>"test-more",
        "version"=>"0.0.6",
        "abstract"=>"TAP Testing for Bash",
        "homepage"=>"http://bpan.org/package/test-more/",
        "license"=>"MIT",
        "copyright"=>"2013, 2014",
        "author"=>{
          "name"=>"Ingy döt Net",
          "email"=>"ingy@ingy.net",
          "github"=>"ingydotnet",
          "twitter"=>"ingydotnet",
          "freenode"=>"ingy",
          "homepage"=>"http://ingy.net"
        },
        "requires"=>{"bash"=>"3.2.0", "bashplus"=>"0.0.1", "test-tap"=>"0.0.1"},
        "test"=>{"cmd"=>"make test"},
        "install"=>{"cmd"=>"make install"},
        "devel"=> {
          "git"=>"git@github.org/ingydotnet/test-more-bash.git",
          "irc"=>"irc.freenode.net/bpan",
          "bug"=>"https://github.com/ingydotnet/test-more-bash/issues/"
        },
        "release"=>{
          "sha"=>"88ace73562fae962b2bdfd3e29d7738a4c274bfd",
          "url"=>"/Users/aocole/developer/ingy/bpan/test/package",
          "timestamp"=>1397647752
        }
      }
    }
    assert_equal(expected['test-more'], packages['test-more'])
    assert_equal(expected['test-more/ingydotnet'], packages['test-more/ingydotnet'])
    assert_not_equal(expected['test-more/ingydotnet/0.0.6']['release']['timestamp'], packages['test-more/ingydotnet/0.0.6']['release']['timestamp'])
    packages['test-more/ingydotnet/0.0.6']['release']['timestamp'] = expected['test-more/ingydotnet/0.0.6']['release']['timestamp']
    assert_equal(expected['test-more/ingydotnet/0.0.6'], packages['test-more/ingydotnet/0.0.6'])
    reset_remote

  end

end
