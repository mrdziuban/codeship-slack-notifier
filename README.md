# Codeship Slack Notifier

This is a simple Ruby web app that notifies your Slack channel with the status of your Codeship builds. It works by receiving Codeship webhooks and forwarding on the message to Slack.

The main difference between this and Codeship's official Slack integration is the ability to specify which GitHub branches you want monitored. For example, you might only want notifications about builds for your `master` branch.

### Getting Started

1. Clone this repo
2. `bundle install`
3. `cp config.sample.yml config.yml`
4. Replace examples in `config.yml`
5. `ruby app.rb`
6. Set up a [Codeship webhook](https://codeship.com/documentation/integrations/webhooks/) for your endpoint
7. Set up an 'Incoming Webhook' in your Slack integrations

### Configuration

These are the options that you can/should specify in `config.yml`:

```yml
slack:                                 # Global Slack settings
  webhook_url: SLACK_WEBHOOK_URL       # Your Slack webhook URL
  username: SLACK_USERNAME             # The Slack username you want the notifications to post from
  channel: NOTIFICATIONS               # The Slack channel you want the notifications to post to
  channel-testing: null                # Suppress alerts for the "testing" state

branches_to_handle:                    # The branches that you want Codeship notifications for
  master:                              # Default settings can be overridden per-branch
    channel: [ ALERTS, NOTIFICATIONS ] # Multiple channels are okay
    channel-success: NOTIFICATIONS     # Note that "channel-testing: null" is still implied here
  develop: null                        # Set to null to use default settings for this branch
  all: null                            # Specify 'all: null' if you want to be notified for all branches

# branches_to_handle:                  # If you don't want branch-specific settings an array is okay
# - master
# - develop
```

If you want to run this app on a port other than 9876, specify the `PORT` variable when starting the app

```bash
$ PORT=9877 ruby app.rb
```

### License

Code released under [the MIT License](LICENSE).
