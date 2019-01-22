require_relative '../lib/config'
require_relative '../lib/reminder'

module GitHubReminder
  class CommandLine
    class << self
      def run options: nil, config: nil 
        options ||= default_options.merge(parse_options)

        p options

        early_exit_options options

        config ||= read_config(options[:config_file])

        reminder = GitHubReminder::Reminder.new config

        if options[:display_issues]
          puts reminder.display_all_issues
        end

        if options[:email_issues]
          reminder.remind_all_issues
        end
      end

      def early_exit_options options
        if options[:show_help]
          puts option_parser({})
          exit
        elsif options[:generate_config]
          generate_config options[:config_file]
          exit
        end
      end

      def generate_config path = nil
        example = GitHubReminder::Config.generate_example

        if path
          File.open(path, "w") { |f| f.puts example }
        else
          puts example
        end
      end

      def read_config path
        GitHubReminder::Config.from_file path 
      end

      def default_options
        {
          config_file: File.join(__dir__, "..", "github_reminder.json"),
          display_issues: true,
          email_issues: true
        }
      end

      def parse_options args = ARGV
        output_opts = {}
        option_parser(output_opts).parse args
        output_opts
      end

      def option_parser options
        require 'optparse'

        OptionParser.new do |opts|
          opts.banner = "Usage: github-reminder [options]"

          opts.on "-c", "--config-file FILE", "Specify configuration file to use" do |file|
            options[:config_file] = file
          end

          opts.on "-g", "--generate-config", "Generate configuration file to use" do
            options[:generate_config] = true
          end

          opts.separator ''

          opts.on '-d', '--[no-]display-issues', 'Write issue reports to console (Default)' do |display|
            options[:display_issues] = display
          end

          opts.on '-e', '--[no-]email-issues', 'Send issues via email (Default)' do |email|
            options[:email_issues] = email
          end

          opts.separator ''

          opts.on_tail "-h", "--help", "Display help message" do
            options[:show_help] = true
          end
        end
      end
    end
  end
end
