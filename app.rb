require 'json'
require 'openssl'
require 'sinatra/config_file'

require_relative 'jobs/codeship_checker_job'

class CodeshipSlackNotifier < Sinatra::Base
  set :server, :puma
  set :port, (ENV['PORT'] || 9876).to_i

  register Sinatra::ConfigFile
  config_file 'config.yml'

  private

  def parse_body
    request.body.rewind
    @body = JSON.parse(request.body.read) rescue {}
    request.body.rewind
  end

  def authorize_request
    signature = env['HTTP_X_HUB_SIGNATURE']
    secret = signature[5..-1]
    return false unless secret && settings.github['post_secret']
    digest = OpenSSL::Digest.new('sha1')
    body = request.body.read
    request.body.rewind
    secret == OpenSSL::HMAC.hexdigest(digest, settings.github['post_secret'], body)
  end

  def handle_webhook
    parse_body
    halt 401 unless authorize_request
    halt 422 unless @body['ref'] && @body['head']
    halt 204 unless settings.branches_to_handle.include?(@body['ref'].split('/').last) || settings.branches_to_handle.include?('all')
    CodeshipCheckerJob.new.async.perform(settings, @body['head'])
  end

  public

  post '/handle' do
    handle_webhook
  end

  run! if __FILE__ == $0
end
