require 'json'

module GitHubReminder
  class Config
    TOP_LEVEL_KEYS = [:repos, :mail, :github_user, :github_token]
    REPO_KEYS = [:owner, :name]
    MAIL_KEYS = [:server, :sender_address, :receiver_address]
    MAIL_SERVER_KEYS = [:host, :port, :user, :password]

    def self.from_file path
      config = JSON.parse File.read(path), symbolize_names: true
      self.validate config
      self.new config
    end

    def self.generate_example
      example = {
        github_user: "",
        github_token: "",
        mail: {
          server: {
            host: "",
            port: 465,
            user: "",
            password: "",
            ignore_tls_failure: false,
          },
          sender_address: "",
          receiver_address: "",
        },
        repos: [
          {
            owner: "",
            name: "",
          }
        ]
      }

      self.validate example

      JSON.pretty_generate(example)
    end

    def self.validate config
      raise "Expected configuration to be a hash table" unless config.is_a? Hash

      TOP_LEVEL_KEYS.each do |k|
        raise "Expected #{k} key at top level of configuration" unless config[k]
      end

      raise "Expected repos to be an array in configuration" unless config[:repos].is_a? Array

      config[:repos].each do |r|
        REPO_KEYS.each do |k|
          raise "Expected #{k} key to be a String in repo configuration" unless r[k].is_a? String
        end
      end

      raise "Expected mail to be a hash table in configuration" unless config[:mail].is_a? Hash

      MAIL_KEYS.each do |k|
        raise "Expected #{k} key in mail configuration" unless config[:mail][k]
      end
    end


    def initialize config
      @config = config
    end

    def [] index
      @config[index].tap do |value|
        raise "Expected value for #{index.inspect} in config" unless value
      end
    end
  end
end
