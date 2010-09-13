module RememberTheMilk
  Version = '0.0.1' unless defined?(Version)
  Load = Kernel.method(:load) unless defined?(Load)

  def version
    RememberTheMilk::Version
  end

  def libdir(*args, &block)
    @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/,'')
    libdir = args.empty? ? @libdir : File.join(@libdir, *args.map{|arg| arg.to_s})
  ensure
    if block
      begin
        $LOAD_PATH.unshift(libdir)
        RememberTheMilk.send(:module_eval, &block)
      ensure
        $LOAD_PATH.shift()
      end
    end
  end

  def load(*args, &block)
    Load.call(*args, &block)
  end

  def new(*args, &block)
    Api.new(*args, &block)
  end

  extend self
end

RTM = RememberTheMilk unless defined?(RTM)
Rememberthemilk = RememberTheMilk unless defined?(Rememberthemilk)

require 'md5'
require 'cgi'
require 'net/http'

begin
  require 'rubygems'
rescue LoadError
  nil
end

require 'json' unless defined?(JSON)
require 'options' unless defined?(Options)
require 'orderedhash' unless defined?(OrderedHash)
require 'tzinfo' unless defined?(TZInfo)


RememberTheMilk.libdir do
  load 'error.rb'
  load 'api.rb'
end


if __FILE__ == $0
  options = YAML.load(IO.read(File.expand_path('~/.rtm.yml')))
  api = RememberTheMilk::Api.new(options)
  #p api.ping
  #p api.call('rtm.tasks.getList')
  #p api.get_token!
  #p api.call('rtm.settings.getList')
  #p api.localtime(utc)
end
