# frozen_string_literal: true

module RSpec
  module Support
    module Helpers
      def expect_exit_code(expected = 0)
        actual = catch(:exit) do
          yield
          0
        end
        expect(actual).to eq(expected)
        actual
      end

      def sqlite_url(url, dir: nil)
        url = sqlite_db_name(url, dir:)
        if jruby?
          "jdbc:sqlite:#{url}"
        else
          "sqlite://#{url}"
        end
      end

      def sqlite_db_name(url, dir: nil)
        # JDBC driver does not use Dir.pwd for building the path, so we need to construct
        # the correct path ourselves
        jruby? && dir ? File.join(dir, url) : url
      end

      def postgres_url(url)
        if jruby?
          # pgJDBC only accepts `jdbc:postgresql://host:port/dbname` URLs, with credentials
          # as `?user=&password=` query params (it does not parse `user:password@` userinfo),
          # so convert CRuby-style `postgres://user:pass@host:port/dbname` URLs accordingly.
          uri = URI(url)
          jdbc_url = +"jdbc:postgresql://#{uri.host}"
          jdbc_url << ":#{uri.port}" if uri.port
          jdbc_url << uri.path.to_s
          params = URI.decode_www_form(uri.query || "").to_h
          params["user"] = uri.user if uri.user
          params["password"] = uri.password if uri.password
          jdbc_url << "?#{URI.encode_www_form(params)}" unless params.empty?
          jdbc_url
        else
          url
        end
      end

      def jruby?
        RUBY_ENGINE == "jruby"
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Helpers
end
