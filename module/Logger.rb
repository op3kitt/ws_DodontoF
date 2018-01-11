#--*-coding:utf-8-*--

require 'logger'

class Logger
  alias_method :__fatal, :fatal
  alias_method :__error, :error
  alias_method :__warn, :warn
  alias_method :__debug, :debug
  alias_method :__info, :info
  private :__fatal, :__error, :__warn, :__debug, :__info

  def fatal(target, *values)
    __fatal("#{target}: #{values.pretty_inspect.strip}")
  end
  def error(target, *values)
    __error("#{target}: #{values.pretty_inspect.strip}")
  end
  def warn(target, *values)
    __warn("#{target}: #{values.pretty_inspect.strip}")
  end
  def debug(target, *values)
    __debug("#{target}: #{values.pretty_inspect.strip}")
  end
  def info(target, *values)
    __info("#{target}: #{values.pretty_inspect.strip}")
  end
end