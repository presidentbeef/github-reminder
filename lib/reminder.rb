require 'erb'
require_relative 'issues'
require_relative 'mail'
require_relative 'repo'

module GitHubReminder
  class Reminder
    attr_reader :config

    def initialize config
      @config = config
    end

    def remind_all_issues
      config[:repos].each do |repo|
        remind_issues repo[:owner], repo[:name]
      end
    end

    def remind_issues owner, project 
      issues = get_issues owner, project

      send_issues issues.issues_with_no_response, project
    end

    def get_issues owner, project
      repo = GitHubReminder::Repo.new(owner, project, config[:github_token])
      GitHubReminder::Issues.new(repo.fetch_open_issues, config[:github_user])
    end

    def send_issues issues, project 
      subject = if issues.any?
                  "#{issues.length} issues for #{project} awaiting response"
                else
                  "Your GitHub queue for #{project} is empty"
                end

      plain_email = format_message(issues, plain_template)
      html_email = format_message(issues, html_template)

      m = GitHubReminder::Mail.new(**config[:mail][:server])
      m.send_message config[:mail][:sender_address], config[:mail][:receiver_address], subject, plain_email, html_email
    end

    def format_message issues, template 
      ERB.new(template).result(binding)
    end

    def plain_template
      @plain_template ||= File.read(File.join(__dir__, "email/plain.erb"))
    end

    def html_template
      @html_template ||= File.read(File.join(__dir__, "email/html.erb"))
    end
  end
end
