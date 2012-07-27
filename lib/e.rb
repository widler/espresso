require 'rubygems'
require 'thread'
require 'monitor'
require 'digest'
require 'cgi'
require 'erb'
require 'tilt'
require 'appetite'

class E < Appetite
  
end

class Module
  def mount *roots, &setup
    ::EApp.new.mount self, *roots, &setup
  end

  def run *args
    mount.run *args
  end
end

require 'e/class'
require 'e/instance'
require 'e/helpers/crud'
require 'e/helpers/view'
require 'e/helpers/cache'
require 'e/helpers/assets'
require 'e/app'
