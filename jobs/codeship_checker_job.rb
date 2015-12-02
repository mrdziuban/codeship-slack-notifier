require 'json'
require 'open-uri'
require 'slack/post'
require 'sucker_punch'

class CodeshipCheckerJob
  include SuckerPunch::Job

  def perform(settings, git_commit)
    @settings = settings
    @git_commit = git_commit

    attempted_build_finds = 0
    times_looped = 0
    loop do
      build = builds.find {|b| b['commit_id'] == @git_commit}
      unless build
        return if attempted_build_finds > 5
        attempted_build_finds += 1
        sleep 3
        next
      end

      if build['status'] == 'testing'
        notify_slack(build) if times_looped == 0
        times_looped += 1
        sleep 10
      elsif ['success', 'error'].include?(build['status'])
        notify_slack(build)
        break
      end
    end
  end

  private

  def builds
    JSON.parse(open("https://codeship.com/api/v1/projects/#{@settings.codeship['project_id']}.json?api_key=#{@settings.codeship['api_key']}").read)['builds']
  end

  def build_message(build)
    build_url = "https://codeship.com/projects/#{@settings.codeship['project_id']}/builds/#{build['id']}"
    status_text = case build['status']
                  when 'testing'
                    'is pending'
                  when 'success'
                    'succeeded'
                  when 'error'
                    'FAILED'
                  when 'stopped'
                    'was stopped'
                  when 'infrastructure_failure'
                    'FAILED due to a Codeship error'
                  else
                    'did something weird...'
                  end
    "<#{build_url}|#{build['branch']} build>#{build['github_username'] ? " by #{build['github_username']}" : ''} #{status_text}"
  end

  def notify_slack(build)
    Slack::Post.configure(
      webhook_url: @settings.slack['webhook_url'],
      username: @settings.slack['username']
    )
    Slack::Post.post(build_message(build), @settings.slack['channel'])
  end
end
