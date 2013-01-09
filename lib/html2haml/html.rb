require 'rubygems'
require 'cgi'
require 'nokogiri'
require 'html2haml/html/erb'

# Haml monkeypatches various Nokogiri classes
# to add methods for conversion to Haml.
# @private
module Nokogiri

  module XML
    # @see Nokogiri
    class Node
      # Whether this node has already been converted to Haml.
      # Only used for text nodes and elements.
      #
      # @return [Boolean]
      attr_accessor :converted_to_haml

      # Returns the Haml representation of the given node.
      #
      # @param tabs [Fixnum] The indentation level of the resulting Haml.
      # @option options (see Haml::HTML#initialize)
      def to_haml(tabs, options)
        return "" if converted_to_haml || to_s.strip.empty?
        text = uninterp(self.to_s)
        node = next_sibling
        while node.is_a?(::Nokogiri::XML::Element) && node.name == "loud"
          node.converted_to_haml = true
          text << '#{' <<
            CGI.unescapeHTML(node.inner_text).gsub(/\n\s*/, ' ').strip << '}'

          if node.next_sibling.is_a?(::Nokogiri::XML::Text)
            node = node.next_sibling
            text << uninterp(node.to_s)
            node.converted_to_haml = true
          end

          node = node.next_sibling
        end
        return parse_text_with_interpolation(text, tabs)
      end

      private

      def erb_to_interpolation(text, options)
        return text unless options[:erb]
        text = CGI.escapeHTML(uninterp(text))
        %w[<loud> </loud>].each {|str| text.gsub!(CGI.escapeHTML(str), str)}
        ::Nokogiri::XML.fragment(text).children.inject("") do |str, elem|
          if elem.is_a?(::Nokogiri::XML::Text)
            str + CGI.unescapeHTML(elem.to_s)
          else # <loud> element
            str + '#{' + CGI.unescapeHTML(elem.inner_text.strip) + '}'
          end
        end
      end

      def tabulate(tabs)
        '  ' * tabs
      end

      def uninterp(text)
        text.gsub('#{', '\#{') #'
      end

      def attr_hash
        Hash[attributes.map {|k, v| [k.to_s, v.to_s]}]
      end

      def parse_text(text, tabs)
        parse_text_with_interpolation(uninterp(text), tabs)
      end

      def parse_text_with_interpolation(text, tabs)
        text.strip!
        return "" if text.empty?

        text.split("\n").map do |line|
          line.strip!
          "#{tabulate(tabs)}#{'\\' if Haml::Parser::SPECIAL_CHARACTERS.include?(line[0])}#{line}\n"
        end.join
      end
    end
  end
end

# @private
HAML_TAGS = %w[block loud silent]
#
# HAML_TAGS.each do |t|
#   Nokogiri::XML::ElementContent[t] = {}
#   Nokogiri::XML::ElementContent.keys.each do |key|
#     Nokogiri::XML::ElementContent[t][key.hash] = true
#   end
# end
#
# Nokogiri::XML::ElementContent.keys.each do |k|
#   HAML_TAGS.each do |el|
#     val = Nokogiri::XML::ElementContent[k]
#     val[el.hash] = true if val.is_a?(Hash)
#   end
# end

module Haml
  # Converts HTML documents into Haml templates.
  # Depends on [Hpricot](http://github.com/whymirror/hpricot) for HTML parsing.
  # If ERB conversion is being used, also depends on
  # [Erubis](http://www.kuwata-lab.com/erubis) to parse the ERB
  # and [ruby_parser](http://parsetree.rubyforge.org/) to parse the Ruby code.
  #
  # Example usage:
  #
  #     Haml::HTML.new("<a href='http://google.com'>Blat</a>").render
  #       #=> "%a{:href => 'http://google.com'} Blat"
  class HTML
    # @param template [String, Hpricot::Node] The HTML template to convert
    # @option options :erb [Boolean] (false) Whether or not to parse
    #   ERB's `<%= %>` and `<% %>` into Haml's `=` and `-`
    # @option options :xhtml [Boolean] (false) Whether or not to parse
    #   the HTML strictly as XHTML
    def initialize(template, options = {})
      @options = options

      if template.is_a? Nokogiri::XML::Node
        @template = template
      else
        if template.is_a? IO
          template = template.read
        end

        template = Haml::Util.check_encoding(template) {|msg, line| raise Haml::Error.new(msg, line)}

        if @options[:erb]
          require 'html2haml/html/erb'
          template = ERB.compile(template)
        end

        if template =~ /^\s*<!DOCTYPE/
          @template = Nokogiri.HTML(template)
        else
          @template = Nokogiri::HTML.fragment(template)
          #in order to support CDATA in HTML (which is invalid) try using the XML parser
          # we can detect this when libxml returns error code XML_ERR_NAME_REQUIRED : 68
          if @template.errors.any? { |e| e.code == 68 }
            @template = method = Nokogiri::XML.fragment(template)
          end
        end
      end
    end

    # Processes the document and returns the result as a string
    # containing the Haml template.
    def render
      @template.to_haml(0, @options)
    end
    alias_method :to_haml, :render

    TEXT_REGEXP = /^(\s*).*$/


    # @see Hpricot
    # @private
    class ::Nokogiri::XML::Document
      # @see Haml::HTML::Node#to_haml
      def to_haml(tabs, options)
        (children || []).inject('') {|s, c| s << c.to_haml(0, options)}
      end
    end

    class ::Nokogiri::XML::DocumentFragment
      # @see Haml::HTML::Node#to_haml
      def to_haml(tabs, options)
        (children || []).inject('') {|s, c| s << c.to_haml(0, options)}
      end
    end

    # @see Hpricot
    # @private
    class ::Nokogiri::XML::ProcessingInstruction
      # @see Haml::HTML::Node#to_haml
      def to_haml(tabs, options)
        "#{tabulate(tabs)}!!! XML\n"
      end
    end

    # @see Hpricot
    # @private
    class ::Nokogiri::XML::CDATA
      # @see Haml::HTML::Node#to_haml
      def to_haml(tabs, options)
        content = parse_text_with_interpolation(
          erb_to_interpolation(self.content, options), tabs + 1)
        "#{tabulate(tabs)}:cdata\n#{content}"
      end

      # removes the start and stop markers for cdata
      def content_without_cdata_tokens
        content.
          gsub(/^\s*<!\[CDATA\[\n/,"").
          gsub(/^\s*]]>\n/, "")
      end
    end

    # @see Hpricot
    # @private
    class ::Nokogiri::XML::DTD
      # @see Haml::HTML::Node#to_haml
      def to_haml(tabs, options)
        attrs = external_id.nil? ? ["", "", ""] :
          external_id.scan(/DTD\s+([^\s]+)\s*([^\s]*)\s*([^\s]*)\s*\/\//)[0]
        raise Haml::SyntaxError.new("Invalid doctype") if attrs == nil

        type, version, strictness = attrs.map { |a| a.downcase }
        if type == "html"
          version = ""
          strictness = "strict" if strictness == ""
        end

        if version == "1.0" || version.empty?
          version = nil
        end

        if strictness == 'transitional' || strictness.empty?
          strictness = nil
        end

        version = " #{version.capitalize}" if version
        strictness = " #{strictness.capitalize}" if strictness

        "#{tabulate(tabs)}!!!#{version}#{strictness}\n"
      end
    end

    # @see Hpricot
    # @private
    class ::Nokogiri::XML::Comment
      # @see Haml::HTML::Node#to_haml
      def to_haml(tabs, options)
        content = self.content
        if content =~ /\A(\[[^\]]+\])>(.*)<!\[endif\]\z/m
          condition = $1
          content = $2
        end

        if content.include?("\n")
          "#{tabulate(tabs)}/#{condition}\n#{parse_text(content, tabs + 1)}"
        else
          "#{tabulate(tabs)}/#{condition} #{content.strip}\n"
        end
      end
    end

    # @see Hpricot
    # @private
    class ::Nokogiri::XML::Element
      # @see Haml::HTML::Node#to_haml
      def to_haml(tabs, options)
        return "" if converted_to_haml
        if name == "script" &&
            (attr_hash['type'].nil? || attr_hash['type'].to_s == "text/javascript") &&
            (attr_hash.keys - ['type']).empty?
          return to_haml_filter(:javascript, tabs, options)
        elsif name == "style" &&
            (attr_hash['type'].nil? || attr_hash['type'].to_s == "text/css") &&
            (attr_hash.keys - ['type']).empty?
          return to_haml_filter(:css, tabs, options)
        end

        output = tabulate(tabs)
        if options[:erb] && HAML_TAGS.include?(name)
          case name
          when "loud"
            lines = CGI.unescapeHTML(inner_text).split("\n").
              map {|s| s.rstrip}.reject {|s| s.strip.empty?}
            lines.first.gsub!(/^[ \t]*/, "= ")

            if lines.size > 1 # Multiline script block
              # Normalize the indentation so that the last line is the base
              indent_str = lines.last[/^[ \t]*/]
              indent_re = /^[ \t]{0,#{indent_str.count(" ") + 8 * indent_str.count("\t")}}/
              lines.map! {|s| s.gsub!(indent_re, '')}

              # Add an extra "  " to make it indented relative to "= "
              lines[1..-1].each {|s| s.gsub!(/^/, "  ")}

              # Add | at the end, properly aligned
              length = lines.map {|s| s.size}.max + 1
              lines.map! {|s| "%#{-length}s|" % s}

              if next_sibling && next_sibling.is_a?(Nokogiri::XML::Element) && next_sibling.name == "loud" &&
                  next_sibling.inner_text.split("\n").reject {|s| s.strip.empty?}.size > 1
                lines << "-#"
              end
            end
            return lines.map {|s| output + s + "\n"}.join
          when "silent"
            return CGI.unescapeHTML(inner_text).split("\n").map do |line|
              next "" if line.strip.empty?
              "#{output}- #{line.strip}\n"
            end.join
          when "block"
            return render_children("", tabs, options)
          end
        end

        if self.next && self.next.text? && self.next.content =~ /\A[^\s]/
          if self.previous.nil? || self.previous.text? &&
              (self.previous.content =~ /[^\s]\Z/ ||
               self.previous.content =~ /\A\s*\Z/ && self.previous.previous.nil?)
            nuke_outer_whitespace = true
          else
            output << "= succeed #{self.next.content.slice!(/\A[^\s]+/).dump} do\n"
            tabs += 1
            output << tabulate(tabs)
            #empty the text node since it was inserted into the block
            self.next.content = ""
          end
        end

        output << "%#{name}" unless name.to_s == 'div' &&
          (static_id?(options) ||
           static_classname?(options) &&
           attr_hash['class'].to_s.split(' ').any?(&method(:haml_css_attr?)))

        if attr_hash

          if static_id?(options)
            output << "##{attr_hash['id'].to_s}"
            remove_attribute('id')
          end
          if static_classname?(options)
            leftover = attr_hash['class'].to_s.split(' ').reject do |c|
              next unless haml_css_attr?(c)
              output << ".#{c}"
            end
            remove_attribute('class')
            set_attribute('class', leftover.join(' ')) unless leftover.empty?
          end
          output << haml_attributes(options) if attr_hash.length > 0
        end

        output << ">" if nuke_outer_whitespace
        output << "/" if to_xhtml.end_with?("/>")

        if children && children.size == 1
          child = children.first
          if child.is_a?(::Nokogiri::XML::Text)
            if !child.to_s.include?("\n")
              text = child.to_haml(tabs + 1, options)
              return output + " " + text.lstrip.gsub(/^\\/, '') unless text.chomp.include?("\n")
              return output + "\n" + text
            elsif ["pre", "textarea"].include?(name) ||
                (name == "code" && parent.is_a?(::Nokogiri::XML::Element) && parent.name == "pre")
              return output + "\n#{tabulate(tabs + 1)}:preserve\n" +
                inner_text.gsub(/^/, tabulate(tabs + 2))
            end
          elsif child.is_a?(::Nokogiri::XML::Element) && child.name == "loud"
            return output + child.to_haml(tabs + 1, options).lstrip
          end
        end

        render_children(output + "\n", tabs, options)
      end

      private

      def render_children(so_far, tabs, options)
        (self.children || []).inject(so_far) do |output, child|
          output + child.to_haml(tabs + 1, options)
        end
      end

      def dynamic_attributes
        @dynamic_attributes ||= begin
          Hash[attr_hash.map do |name, value|
            next if value == ""
            full_match = nil
            ruby_value = value.to_s.gsub(%r{<loud>\s*(.+?)\s*</loud>}) do
              full_match = $`.empty? && $'.empty?
              CGI.unescapeHTML(full_match ? $1: "\#{#{$1}}")
            end
            next if ruby_value == value
            [name.to_s, full_match ? ruby_value : %("#{ruby_value}")]
          end]
        end
      end

      def to_haml_filter(filter, tabs, options)
        content =
          if children.first.cdata?
            children.first.content_without_cdata_tokens
          else
            CGI.unescapeHTML(self.inner_text)
          end

        content = erb_to_interpolation(content, options)
        content.gsub!(/\A\s*\n(\s*)/, '\1')
        original_indent = content[/\A(\s*)/, 1]
        if content.split("\n").all? {|l| l.strip.empty? || l =~ /^#{original_indent}/}
          content.gsub!(/^#{original_indent}/, tabulate(tabs + 1))
        end

        "#{tabulate(tabs)}:#{filter}\n#{content}"
      end

      def static_attribute?(name, options)
        attr_hash[name] && !dynamic_attribute?(name, options)
      end

      def dynamic_attribute?(name, options)
        options[:erb] and dynamic_attributes.key?(name)
      end

      def static_id?(options)
        static_attribute?('id', options) && haml_css_attr?(attr_hash['id'])
      end

      def static_classname?(options)
        static_attribute?('class', options)
      end

      def haml_css_attr?(attr)
        attr =~ /^[-:\w]+$/
      end

      # Returns a string representation of an attributes hash
      # that's prettier than that produced by Hash#inspect
      def haml_attributes(options)
        attrs = attr_hash.sort.map do |name, value|
          haml_attribute_pair(name, value.to_s, options)
        end
        if options[:html_style_attributes]
          "(#{attrs.join(' ')})"
        else
          "{#{attrs.join(', ')}}"
        end
      end

      # Returns the string representation of a single attribute key value pair
      def haml_attribute_pair(name, value, options)
        value = dynamic_attribute?(name, options) ? dynamic_attributes[name] : value.inspect
        if options[:html_style_attributes]
          "#{name}=#{value}"
        else
          name = name.index(/\W/) ? name.inspect : ":#{name}"
          "#{name} => #{value}"
        end
      end
    end
  end
end
