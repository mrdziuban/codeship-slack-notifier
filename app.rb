require 'json'
require 'logger'
require 'openssl'
require 'slack/post'
require 'sinatra/config_file'

class CodeshipSlackNotifier < Sinatra::Base
  set :server, :puma
  set :port, (ENV['PORT'] || 9876).to_i
  set :bind, '0.0.0.0'

  register Sinatra::ConfigFile
  config_file 'config.yml'

  Logger.class_eval { alias :write :'<<' }
  access_log = File.open(File.join(settings.root, 'log', "#{settings.environment}_access.log"), 'a+')
  access_log.sync = true
  access_logger = Logger.new(access_log)
  error_log = File.open(File.join(settings.root, 'log', "#{settings.environment}_error.log"), 'a+')
  error_log.sync = true

  configure do
    enable :logging
    use Rack::CommonLogger, access_logger
  end

  before { env['rack.errors'] = error_log }

  private

  def parse_body
    request.body.rewind
    @body = JSON.parse(request.body.read) rescue {}
    request.body.rewind
  end

  def handle_webhook
    parse_body
    halt 422 unless @body['build']
    halt 204 unless settings.branches_to_handle.include?(@body['build']['branch']) || settings.branches_to_handle.include?('all')
    notify_slack
  end

  def status_text(status)
    case status
    when 'testing'
      'is pending'
    when 'success'
      'succeeded'
    when 'error'
      'FAILED'
    when 'stopped'
      'was stopped'
    when 'waiting'
      'is waiting to start'
    when 'infrastructure_failure'
      'FAILED due to a Codeship error'
    when 'ignored'
      'was ignored because the account is over the monthly build limit'
    when 'blocked'
      'was blocked because of excessive resource consumption'
    else
      'did something weird...'
    end
  end

  def build_message
    build = @body['build']
    message = "<#{build['build_url']}|#{build['branch']}> build"
    message += " by #{build['committer']}" if build['committer']
    message += " (<#{build['commit_url']}|#{build['commit_id'][0..6]}>)" if build['commit_id'] && build['commit_url']
    message += status_text(build['status'])
    message
  end

  def notify_slack(message = false)
    Slack::Post.configure(
      webhook_url: settings.slack['webhook_url'],
      username: settings.slack['username']
    )
    message = message || build_message
    Slack::Post.post(message, settings.slack['channel'])
  end

  public

  post '/handle' do
    handle_webhook
  end

  run! if __FILE__ == $0
end
