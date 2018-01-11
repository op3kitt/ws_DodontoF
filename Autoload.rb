#--*-coding:utf-8-*--

$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems' if RUBY_VERSION < '1.9.0'

require 'fssm'
require 'cgi'
require 'filelist' unless defined?(FileList)
require 'pp' unless defined?(pp)
require 'kconv' unless defined?(kconv)
require 'webrick' unless defined?(webrick)
require 'json' unless defined?(json)
require 'em-websocket' unless defined?(em-websocket)

require 'lib/json/jsonParser'

begin
  require 'msgpack'
rescue LoadError
  if RUBY_VERSION >= '1.9.0'
    require 'lib/msgpack19'
  else
    require 'lib/msgpackPure'
  end
end

if( RUBY_VERSION >= '1.9.0' )
  Encoding.default_external = 'utf-8'
else
  require 'jcode'
end

$main_class = Kernel unless defined?($main_class)

module Autoload
  extend self

  def requireAll(target, recursive = false)
    target.each do |file|
      require file
    end
  end

  def autoload(target, parent = $main_class)
    target.each do |file|
      parent.autoload File.basename(file, '.rb'), file
    end
  end
end

Autoload.requireAll(FileList['module/*.rb'])
