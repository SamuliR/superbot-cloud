# frozen_string_literal: true

require 'net/http'
require 'launchy'

module Superbot
  module CLI
    module Cloud
      class LoginCommand < Clamp::Command
        option ['-i', '--interactive'], :flag, 'interactive login from command line'
        option ['-f', '--force'], :flag, 'force override current credentials'

        def execute
          return proceed_to_login if force? || Superbot::Cloud.credentials.nil?

          begin
            Superbot::Cloud::Api.request(:token)
            puts "Logged in as #{Superbot::Cloud.credentials[:email]}"
          rescue SystemExit => e
            abort unless e.message == 'Invalid credentials'
            proceed_to_login
          end
        end

        def proceed_to_login
          interactive? ? console_login : web_login
        end

        def console_login
          email = (print 'Email: '; $stdin.gets.rstrip)
          password = (print 'Password: '; $stdin.gets.rstrip)
          api_response = Superbot::Cloud::Api.request(:login, params: { email: email, password: password })
          Superbot::Cloud.save_credentials(api_response)
        end

        def web_login
          Superbot::Cloud::WebLogin.run!
          Launchy.open(cloud_login_uri)

          puts "Your browser has been opened to visit:"
          puts cloud_login_uri
          puts ""
          puts "Press enter to exit"
          $stdin.gets
        end

        def cloud_login_uri
          URI.parse(Superbot::Cloud::LOGIN_URI).tap do |uri|
            uri.query = URI.encode_www_form(redirect_uri: 'http://localhost:4567/login')
          end.to_s
        end
      end
    end
  end
end
