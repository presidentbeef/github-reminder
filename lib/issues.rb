require 'json'
require 'net/http'
require 'base64'

module GitHubReminder
  class Issues
    attr_reader :issues, :pull_requests

    def initialize open_issues, owner
      @user = @owner = owner
      @issues = []
      @pull_requests = []

      open_issues.each do |i|
        if i.pull_request?
          @pull_requests << i
        else
          @issues << i
        end
      end

      @pull_requests.sort_by! { |pr| pr.id }
      @issues.sort_by! { |i| i.id }

      @pull_requests.reverse!
      @issues.reverse!
    end

    def prs_with_no_response
      @pull_requests.select do |i|
        i.no_comments? and i.creator != @owner
      end
    end

    def issues_with_no_response
      @issues.select do |i|
        i.no_comments?
      end
    end

    def last_response_not_me
      iss = @issues.select do |i|
        i.last_comment and i.last_comment.user_name != @user
      end

      prs = @pull_requests.select do |i|
        i.last_comment and i.last_comment.user_name != @user
      end

      iss.concat prs
    end
  end

  class Issue
    attr_accessor :last_comment

    def initialize issue
      @issue = issue
    end

    def id
      @issue['number']
    end

    def pull_request?
      !!@issue['pull_request']
    end

    def issue?
      !pull_Request
    end

    def no_comments?
      @issue['comments'] == 0
    end

    def link
      @issue['html_url']
    end

    def pretty
      "##{self.id} #{@issue['title']}"
    end

    def creator
      @issue['user']['login']
    end
  end

  class Comment
    def initialize comment
      @comment = comment
    end

    def user_name
      @comment['user']['login']
    end
  end
end
