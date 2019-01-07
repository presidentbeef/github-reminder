require 'date'
require 'net/smtp'
require 'securerandom'

module GitHubReminder
  # Manages sending emails.
  class Mail
    
    # Set up mail server information.
    #
    # It is highly recommended to not `ignore_tls_failure`, as it means
    # trusting TLS certificates returned by the server that may be evil,
    # but sometimes it is unavoidable.
    def initialize host:, port: 465, user:, password:, ignore_tls_failure: false
      @host = host
      @port = port
      @user = user
      @password = password
      @ignore_tls_failure = ignore_tls_failure
    end

    # Sends message to the given recipient.
    #
    # Creates formatted email with plain and HTML messages and sends it.
    def send_message sender, receiver, subject, plain_message, html_message
      message = generate_message sender, receiver, subject, plain_message, html_message

      s = Net::SMTP.new(@host, @port)

      if @ignore_tls_failure
        c = OpenSSL::SSL::SSLContext.new
        c.verify_mode = OpenSSL::SSL::VERIFY_NONE 
        s.enable_tls(c)
      else
        s.enable_tls
      end

      s.start(@host, @user, @password, :plain) do |smtp|
        resp = smtp.send_message message, sender, receiver

        if not resp.success?
          raise "Unexpected response from mail server: #{rep.inspect}"
        end
      end
    end

    # Turns message into a properly-formatted email.
    def generate_message sender, receiver, subject, plain_message, html_message
      boundary = "GHR_#{SecureRandom.hex}"

      <<~EMAIL
      From: GitHub Reminder <#{sender}>
      Date: #{DateTime.now.httpdate} 
      To: #{receiver} <#{receiver}>
      Subject: #{subject} 
      Content-type: multipart/alternative; boundary="#{boundary}"

      > Unsupported MIME type?

      --#{boundary}
      Content-type: text/plain;	charset="UTF-8"

      #{plain_message}

      --#{boundary}
      Content-type: text/html; charset="UTF-8"

      #{html_message}

      --#{boundary}--
      EMAIL
    end
  end
end
