require 'yaml'
require 'oj'

module FaaStRuby
  def self.included(base)
    base.extend(SpecHelper)
    $LOAD_PATH << Dir.pwd
  end
  class DoubleRenderError < StandardError; end
  module SpecHelper
    class Event
      @@event = Struct.new(:body, :query_params, :headers, :context)
      def self.new(body: 'example body', query_params: {'foo' => 'bar'}, headers: {'Foo' => 'Bar'}, context: nil)
        @@event.new(body, query_params, headers, context)
      end
    end
    class Response
      attr_accessor :body, :status, :headers
      @@rendered = false
      def initialize(body, status, headers)
        if @@rendered
          raise FaaStRuby::DoubleRenderError.new("You called 'render' or 'respond_with' multiple times in your handler method.")
        end
        @@rendered = true
        @body = body
        @status = status
        @headers = headers
      end

      def call
        @@rendered = false
        self
      end
    end
  end

  def respond_with(body, status: 200, headers: {})
    SpecHelper::Response.new(body, status, headers)
  end

  def render(js: nil, body: nil, inline: nil, html: nil, json: nil, yaml: nil, text: nil, status: 200, headers: {}, content_type: nil)
    headers["Content-Type"] = content_type if content_type
    case
    when json
      headers["Content-Type"] ||= "application/json"
      resp_body = json.is_a?(String) ? json : Oj.dump(json)
    when html, inline
      headers["Content-Type"] ||= "text/html"
      resp_body = html
    when text
      headers["Content-Type"] ||= "text/plain"
      resp_body = text
    when yaml
      headers["Content-Type"] ||= "application/yaml"
      resp_body = yaml.is_a?(String) ? yaml : yaml.to_yaml
    when body
      headers["Content-Type"] ||= "application/octet-stream"
      resp_body = raw
    when js
      headers["Content-Type"] ||= "text/javascript"
      resp_body = js
    end
    respond_with(resp_body, status: status, headers: headers)
  end
end
