require 'json'
require_relative 'lib/config'
require_relative 'lib/reminder'

def handler event
  if not event.context.is_a? String
    render(text: "No configuration information")
  else
    setup = JSON.parse(event.context, symbolize_names: true)

    GitHubReminder::Config.validate setup
    config = GitHubReminder::Config.new(setup)

    reminder = GitHubReminder::Reminder.new(config)
    reminder.remind_all_issues

    counts = { repos: 0, issues: 0 }
    reminder.each_issue_with_no_response do |owner, project, issues|
      counts[:repos] += 1
      counts[:issues] += issues.length
    end

    render json: JSON.pretty_generate(counts)
  end
rescue => e
  render text: e.inspect
end
