require 'net/http'
require 'json'

module PivotalTracker
  class Client
    def initialize(url: , token: , logger: nil)
      @uri = URI(url)
      @token = token
      @http_client = NetHTTPClient.new(logger: logger)
    end

    def api
      V5API.new(self)
    end

    def uri(path = nil, query: {})
      @uri.clone.tap do |uri|
        uri.path = uri.path + path.gsub(/^([^\/])/, '/\1') if path
        uri.query = URI.encode_www_form(query) if query.any?
      end
    end

    def request(method, url_path = "", body: nil, query: {})
      resp = @http_client.
        request(method, uri(url_path, query: query)) do |req|
          req['X-TrackerToken'] = @token
          req['User-Agent'] = user_agent
          req.body = body unless body.nil?
          req
        end

      PivotalTracker::ClientResponse.new(resp)
    end

    protected

    def user_agent
      @user_agent ||= "pivotaltracker-client.rb/alpha"
    end
  end

  class NetHTTPClient
    def initialize(logger: nil, open_timeout: 2, read_timeout: 2)
      @logger = logger
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def request(method, uri, &req_block)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout

      http.start do
        req = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
        req = req_block.call(req)

        logging(http, req)
      end
    end

    def logging(http, req)
      log_headers = -> (headers) {
        log headers.canonical_each.map {|k, v| "#{k}: #{v}\n" }.join
        log "\n"
      }

      log "-> #{req.method} #{req.path} #{req.uri.query}\n"
      log_headers.call req

      resp = http.request(req)

      log "<- #{resp.code}\n"
      log_headers.call resp

      resp
    end

    def log(str)
      @logger.write(str) if @logger
    end
  end

  class ClientResponse
    attr_reader :http_response

    def initialize(http_response)
      @http_response = http_response
    end

    def parsed_body
      JSON[http_response.body]
    end
  end

  class V5API
    def initialize(client)
      @client = client
    end

    def projects
      @client.request(:get, 'projects').parsed_body
    end

    def stories(project_id, query: {})
      @client.request(:get, "projects/#{project_id}/stories", query: query).parsed_body
    end

    def memberships(project_id, query: {})
      @client.request(:get, "projects/#{project_id}/memberships", query: query).parsed_body
    end
  end
end
