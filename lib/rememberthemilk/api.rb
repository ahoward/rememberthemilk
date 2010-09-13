module RememberTheMilk
  class Api
    Host = 'www.rememberthemilk.com' unless defined?(Host)
    Url = "http://#{ Host }" unless defined?(Url)

    class << Api
      def url_for(*args)
        options = args.options.pop

        service = options[:service] || :rest
        url = "/services/#{ service }" 
        url += args.flatten.compact.join('/') unless args.empty?
        url.squeeze('/')
        url.chomp!('/')
        url += '/'

        query = options[:query] || {}
        unless query.empty?
          url = url + '?' + query_string_for(query)
        end

        if options[:absolute]
          url = Url + url
        end

        url
      end

      def query_string_for(query)
        query.to_a.map{|k,v| [escape(k), escape(v)].join('=')}.join('&')
      end

      def escape(val)
        CGI::escape(val.to_s).gsub(/ /, '+')
      end
    end

    attr_accessor :api_key
    attr_accessor :shared_secret
    attr_accessor :frob
    attr_accessor :token
    attr_accessor :username
    attr_accessor :password

    def initialize(*args, &block)
      options = args.options
      @api_key = options[:api_key]
      @shared_secret = options[:shared_secret]
      @frob = options[:frob]
      @token = options[:token]
      @username = options[:username]
      @password = options[:password]
    end

    def apply_for_an_api_key
      url = 'http://www.rememberthemilk.com/services/api/keys.rtm'
      puts(url)
      open(url)
    end

    def api_sig_for(query)
      kvs = query.to_a.map{|k,v| [k.to_s, v.to_s]}.sort
      MD5.md5(@shared_secret + kvs.join).to_s
    end

    def ping
      call('rtm.test.echo')
    end

    def call(method, *args, &block)
      options = args.options

      query = Hash.new
      query['method'] = method unless method.to_s.empty?
      query['api_key'] = @api_key
      query['auth_token'] = @token
      query['format'] = 'json' 
      options.each do |key, val|
        query[key] = val
      end
      query['api_sig'] = api_sig_for(query)

      url = Api.url_for(:query => query, :service => 'rest')
      response = Net::HTTP.get_response(Host, url)

      json = JSON.parse(response.body)

      rsp = json['rsp']

      if rsp['stat'] != 'ok'
        raise(Error, "#{ method }(#{ args.inspect }) @ #{ url } #=> #{ rsp.inspect }")
      end

      rsp
    end

    def localtime(time)
      time = Time.parse(time.to_s) unless time.is_a?(Time)
      @settings ||= call('rtm.settings.getList')
      @timezone = TZInfo::Timezone.get(@settings['settings']['timezone'])
      @timezone.utc_to_local(time.utc)
    end

  # see: http://www.rememberthemilk.com/services/api/authentication.rtm
  #
    def get_token!
      require 'mechanize'
      require 'pp'
      frob = get_frob
      query = Hash.new
      query[:frob] = frob
      query[:api_key] = @api_key
      query[:perms] = 'delete'
      query['api_sig'] = api_sig_for(query)
      url = Api.url_for(:query => query, :service => :auth, :absolute => true)
      response = Net::HTTP.get_response(Host, url)
      location = response.header['Location']
      m = Mechanize.new
      page = m.get(url)
      form = page.forms.first
      form['username'] = @username
      form['password'] = @password
      page = form.submit
      rsp = call('rtm.auth.getToken', :frob => frob)
      token = rsp['auth']['token']
    end

    def get_frob
      rsp = call('rtm.auth.getFrob')
      rsp['frob']
    end
  end
end
