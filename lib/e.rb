require 'rubygems'
require 'thread'
require 'monitor'
require 'digest'
require 'cgi'
require 'erb'

require 'tilt'

$:.unshift File.expand_path('../../../meister/lib', __FILE__)
require 'meister'

class E < ::Meister
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
require 'e/extensions/crud'
require 'e/app'
