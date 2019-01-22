require 'erb'
require_relative 'issues'
require_relative 'mail'
require_relative 'repo'

module GitHubReminder
  class Reminder
    attr_reader :config

    def initialize config
      @config = config
      @issue_cache = {}
    end

    def each_issue_with_no_response
      get_all_issues.each do |owner, projects|
        projects.each do |project, issues|
          yield owner, project, issues.issues_with_no_response
        end
      end
    end

    def get_all_issues
      return @issue_cache unless @issue_cache.empty?

      config[:repos].each do |repo|
        issues = get_issues repo[:owner], repo[:name]

        @issue_cache[repo[:owner]] ||= {}
        @issue_cache[repo[:owner]][repo[:name]] = issues
      end

      @issue_cache
    end

    def remind_all_issues
      each_issue_with_no_response do |owner, project, issues|
        remind_issues project, issues
      end
    end

    def display_all_issues
      output = []

      each_issue_with_no_response do |owner, project, issues|
        output << display_issues(owner, project, issues)
      end

      output
    end

    def display_issues owner, project, issues
      <<~OUTPUT
      #{format_subject(issues, project)}

      #{format_message(issues, plain_template)}
      OUTPUT
    end

    def remind_issues project, issues
      send_issues issues, project
    end

    def get_issues owner, project
      repo = GitHubReminder::Repo.new(owner, project, config[:github_token])
      GitHubReminder::Issues.new(repo.fetch_open_issues, config[:github_user])
    end

    def send_issues issues, project 
      subject = format_subject(issues, project)

      plain_email = format_message(issues, plain_template)
      html_email = format_message(issues, html_template)

      m = GitHubReminder::Mail.new(**config[:mail][:server])
      m.send_message config[:mail][:sender_address], config[:mail][:receiver_address], subject, plain_email, html_email
    end

    def format_subject issues, project
      if issues.any?
        "#{issues.length} issues for #{project} awaiting response"
      else
        "Your GitHub queue for #{project} is empty"
      end
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
