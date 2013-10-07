require "rubygems"
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start
end

require "bundler/setup"
require "minitest/autorun"
require "html2haml"
require 'html2haml/html'
require 'html2haml/html/erb'

class MiniTest::Unit::TestCase
  protected
  def render(text, options = {})
    Html2haml::HTML.new(text, options).render.rstrip
  end

  def render_erb(text, html_style_attributes = false)
    render(text, :erb => true, :html_style_attributes => html_style_attributes)
  end
end
