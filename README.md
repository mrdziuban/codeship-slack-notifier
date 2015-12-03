# Codeship Slack Notifier

This is a simple Ruby web app that notifies your Slack channel with the status of your Codeship builds. It works by receiving GitHub webhooks for push events and doing background processing to monitor the status of your Codeship builds.

The main difference between this and Codeship's official Slack integration is the ability to specify which GitHub branches you want monitored. For example, you might only want notifications about builds for your `master` branch.

### Getting Started

1. Clone this repo
2. `bundle install`
3. `cp config.sample.yml config.yml`
4. Replace examples in `config.yml`
5. `ruby app.rb`
6. Set up a GitHub webhook for the `push` event that `POST`s to `http://your-domain.com:9876/handle`
7. Set up an 'Incoming Webhook' in your Slack integrations

### Configuration

These are the options that you can/should specify in `config.yml`:

```yml
branches_to_handle:                # The branches that you want Codeship notifications for
  - master
  - develop
  - all                            # Specify 'all' if you want to be notified for all branches
github:
  post_secret: GITHUB_POST_SECRET  # The POST secret you set up in your GitHub webhook
codeship:
  api_key: CODESHIP_API_KEY        # Your Codeship API key
  project_id: 12345                # Your Codeship project's ID
  attempted_build_finds: 5         # OPTIONAL: Times to check Codeship to see if the build exists, defaults to 5
  wait_timeout: 1500               # OPTIONAL: Max seconds to wait for the Codeship build to finish, defaults to 1500
slack:
  webhook_url: SLACK_WEBHOOK_URL   # Your Slack webhook URL
  username: SLACK_USERNAME         # The Slack username you want the notifications to post from
  channel: SLACK_CHANNEL           # The Slack channel you want the notifications to post to
```

If you want to run this app on a port other than 9876, specify the `PORT` variable when starting the app

```bash
$ PORT=9877 ruby app.rb
```

### License

Code released under [the MIT License](LICENSE).
