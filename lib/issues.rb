require 'json'
require 'net/http'
require 'base64'

class Issues
  attr_reader :issues, :pull_requests

  def initialize owner, repo, token
    @user = @owner = owner 
    @repo = repo
    @token = token
    @issues = []
    @pull_requests = []

    open_issues = get_open_issues

    notify "#{open_issues.length} found in #{owner}/#{repo}"

    open_issues.each do |i|
      if i.pull_request?
        @pull_requests << i
      else
        @issues << i
      end

      i.last_comment = get_last_comment i
    end

    @pull_requests.sort_by! { |pr| pr.id }
    @issues.sort_by! { |i| i.id }

    @pull_requests.reverse!
    @issues.reverse!
  end

  def get_open_issues
    issues = []
    page = 1
    path = "/repos/#@owner/#@repo/issues?access_token=#@token&sort=updated&direction=asc&state=open"
    http = Net::HTTP.start("api.github.com", 443, nil, nil, nil, nil, use_ssl: true)

    loop do
      notify "Retrieving page #{page}..."

      resp = http.get(path)
      new_issues = JSON.parse(resp.body)

      unless Array === new_issues then
        abort "bad response: %p" % new_issues
      end

      issues.concat new_issues

      # Pagination
      if resp['Link'] and resp['Link'] =~ /<https:\/\/api\.github\.com(\/[^>]+)>; rel="next",/
        path = $1
        page = path.match(/page=(\d+)/)[1]
      else
        http.finish
        break
      end
    end

    issues.map { |i| Issue.new i }
  end

  def get_last_comment issue
    if issue.no_comments?
      return
    end

    comments = []

    page = 1
    path = "/repos/#@owner/#@repo/issues/#{issue.id}/comments?access_token=#@token"
    http = Net::HTTP.start("api.github.com", 443, nil, nil, nil, nil, use_ssl: true)

    loop do
      notify "Retrieving comments for #{issue.id} (#{page})..."

      resp = http.get(path)
      new_comments = JSON.parse(resp.body)

      unless Array === new_comments then
        error "Tried to get #{path}"
        abort "bad response: %p" % new_comments
      end

      comments.concat new_comments

      # Pagination
      if resp['Link'] and resp['Link'] =~ /<https:\/\/api\.github\.com(\/[^>]+)>; rel="last",/
        path = $1
        page = path.match(/page=(\d+)/)[1]
      else
        http.finish
        break
      end
    end

    Comment.new comments.last
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

  private

  # Print INFO message
  def notify message
    warn "[INFO] #{message}"
  end

  # Print ERROR message
  def error message
    warn "[ERROR] #{message}"
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
