module GitHubReminder
  class Repo
    def initialize owner, repo, token
      @owner = owner
      @repo = repo
      @token = token
    end

    def fetch_open_issues
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

      issues.map do |i|
        Issue.new(i).tap do |issue|
          issue.last_comment = fetch_last_comment issue
        end
      end
    end

    def fetch_last_comment issue
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

      GitHubReminder::Comment.new comments.last
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
end
