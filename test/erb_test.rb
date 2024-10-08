require 'test_helper'

class ErbTest < Minitest::Unit::TestCase
  def test_erb
    assert_equal '- foo = bar', render_erb('<% foo = bar %>')
    assert_equal '- foo = bar', render_erb('<% foo = bar -%>')
    assert_equal '= h @item.title', render_erb('<%=h @item.title %>')
    assert_equal '= h @item.title', render_erb('<%=h @item.title -%>')
  end

  def test_inline_erb
    assert_equal("%p= foo", render_erb("<p><%= foo %></p>"))
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
%p
  = foo
HAML
<p><%= foo %>
</p>
HTML
  end

  def test_non_inline_erb
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
%p
  = foo
HAML
<p>
  <%= foo %>
</p>
HTML
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
%p
  = foo
HAML
<p>
  <%= foo %></p>
HTML
  end

  def test_erb_in_cdata
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
:cdata
  Foo \#{bar} baz
HAML
<![CDATA[Foo <%= bar %> baz]]>
HTML
  end

  def test_erb_in_script
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
:javascript
  function foo() {
    return \#{foo.to_json};
  }
HAML
<script type="text/javascript">
  function foo() {
    return <%= foo.to_json %>;
  }
</script>
HTML
  end

  def test_erb_in_style
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
:css
  foo {
      bar: \#{"baz"};
  }
HAML
<style type="text/css">
    foo {
        bar: <%= "baz" %>;
    }
</style>
HTML
  end

  def test_erb_in_line
    assert_equal 'foo bar #{baz}', render_erb('foo bar <%= baz %>')
    assert_equal 'foo bar #{baz}! Bang.', render_erb('foo bar <%= baz %>! Bang.')
  end

  def test_erb_multi_in_line
    assert_equal('foo bar #{baz}! Bang #{bop}.',
      render_erb('foo bar <%= baz %>! Bang <%= bop %>.'))
    assert_equal('foo bar #{baz}#{bop}!',
      render_erb('foo bar <%= baz %><%= bop %>!'))
  end

  def test_erb_with_html_special_chars
    assert_equal '= 3 < 5 ? "OK" : "Your computer is b0rken"',
      render_erb('<%= 3 < 5 ? "OK" : "Your computer is b0rken" %>')
  end

  def test_erb_in_class_attribute
    assert_equal "%div{:class => dyna_class} I have a dynamic attribute",
      render_erb('<div class="<%= dyna_class %>">I have a dynamic attribute</div>')
  end

  def test_erb_in_id_attribute
    assert_equal "%div{:id => dyna_id} I have a dynamic attribute",
      render_erb('<div id="<%= dyna_id %>">I have a dynamic attribute</div>')
  end

  def test_erb_in_attribute_results_in_string_interpolation
    assert_equal('%div{:id => "item_#{i}"} Ruby string interpolation FTW',
      render_erb('<div id="item_<%= i %>">Ruby string interpolation FTW</div>'))
  end

  def test_erb_in_attribute_with_trailing_content
    assert_equal('%div{:class => "#{12}!"} Bang!',
      render_erb('<div class="<%= 12 %>!">Bang!</div>'))
  end

  def test_erb_in_html_escaped_attribute
    assert_equal '%div{:class => "foo"} Bang!',
      render_erb('<div class="<%= "foo" %>">Bang!</div>')
  end

  def test_erb_in_html_escaped_attribute_with_symbol
    assert_equal '%div{:class => :foo} Bang!',
      render_erb('<div class="<%= :foo %>">Bang!</div>')
  end

  def test_empty_erb_in_attribute
    assert_equal '%div{:class => ""}',
      render_erb('<div class="<%= %>"></div>')
  end

  def test_erb_in_attribute_to_multiple_interpolations
    assert_equal('%div{:class => "#{12} + #{13}"} Math is super',
      render_erb('<div class="<%= 12 %> + <%= 13 %>">Math is super</div>'))
  end

  def test_whitespace_eating_erb_tags
    assert_equal '- form_for', render_erb('<%- form_for -%>')
  end

  def test_interpolation_in_erb
    assert_equal('= "Foo #{bar} baz"', render_erb('<%= "Foo #{bar} baz" %>'))
  end

  def test_interpolation_in_erb_attrs
    assert_equal('%p{:foo => "#{bar} baz"}',
      render_erb('<p foo="<%= "#{bar} baz" %>"></p>'))
  end

  def test_multiline_erb_silent_script
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
.blah
  - foo
  - bar
  - baz
  %p foo
HAML
<div class="blah">
  <%
    foo
    bar
    baz
  %>
  <p>foo</p>
</div>
ERB
  end

  def test_multiline_erb_loud_script
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
.blah
  = foo +            |
      bar.baz.bang + |
    baz              |
  %p foo
HAML
<div class="blah">
  <%=
    foo +
      bar.baz.bang +
    baz
  %>
  <p>foo</p>
</div>
ERB
  end

  def test_weirdly_indented_multiline_erb_loud_script
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
.blah
  = foo +          |
    bar.baz.bang + |
    baz            |
  %p foo
HAML
<div class="blah">
  <%=
    foo +
  bar.baz.bang +
    baz
  %>
  <p>foo</p>
</div>
ERB
  end

  def test_two_multiline_erb_loud_scripts
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
.blah
  = foo +          |
    bar.baz.bang + |
    baz            |
  = foo.bar do |
      bang     |
    end        |
  %p foo
HAML
<div class="blah">
  <%=
    foo +
    bar.baz.bang +
    baz
  %>
  <%= foo.bar do
        bang
      end %>
  <p>foo</p>
</div>
ERB
  end

  def test_multiline_then_single_line_erb_loud_scripts
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
.blah
  = foo +          |
    bar.baz.bang + |
    baz            |
  = foo.bar
  %p foo
HAML
<div class="blah">
  <%=
    foo +
    bar.baz.bang +
    baz
  %>
  <%= foo.bar %>
  <p>foo</p>
</div>
ERB
  end

  def test_multiline_erb_but_really_single_line
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
.blah
  = foo
  %p foo
HAML
<div class="blah">
  <%=
    foo
  %>
  <p>foo</p>
</div>
ERB
  end

  ### Block Parsing

  def test_block_parsing
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- foo do
  %p bar
HAML
<% foo do %>
  <p>bar</p>
<% end %>
ERB
  end

  def test_block_parsing_with_args
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- foo do |a, b, c|
  %p bar
HAML
<% foo do |a, b, c| %>
  <p>bar</p>
<% end %>
ERB
  end

  def test_block_parsing_with_equals
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
= foo do
  %p bar
HAML
<%= foo do %>
  <p>bar</p>
<% end %>
ERB
  end

  def test_block_parsing_with_modified_end
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- foo do
  blah
- end.bip
HAML
<% foo do %>
  blah
<% end.bip %>
ERB
  end

  def test_block_parsing_with_modified_end_with_block
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- foo do
  blah
- end.bip do
  brang
HAML
<% foo do %>
  blah
<% end.bip do %>
  brang
<% end %>
ERB
  end

  def test_multiline_block_opener
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- foo bar
- baz bang
- biddle do
  foo
HAML
<% foo bar
  baz bang
  biddle do %>
    foo
<% end %>
ERB
  end

  def test_if_elsif_else_parsing
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- if foo
  %p bar
- elsif bar.foo("zip")
  #bang baz
- else
  %strong bibble
HAML
<% if foo %>
  <p>bar</p>
<% elsif bar.foo("zip") %>
  <div id="bang">baz</div>
<% else %>
  <strong>bibble</strong>
<% end %>
ERB
  end

  def test_case_when_parsing
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- case foo.bar
- when "bip"
  %p bip
- when "bop"
  %p BOP
- when bizzle.bang.boop.blip
  %em BIZZLE BANG BOOP BLIP
HAML
<% case foo.bar %>
<% when "bip" %>
  <p>bip</p>
<% when "bop" %>
  <p>BOP</p>
<% when bizzle.bang.boop.blip %>
  <em>BIZZLE BANG BOOP BLIP</em>
<% end %>
ERB

    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- case foo.bar
- when "bip"
  %p bip
- when "bop"
  %p BOP
- when bizzle.bang.boop.blip
  %em BIZZLE BANG BOOP BLIP
HAML
<% case foo.bar
   when "bip" %>
  <p>bip</p>
<% when "bop" %>
  <p>BOP</p>
<% when bizzle.bang.boop.blip %>
  <em>BIZZLE BANG BOOP BLIP</em>
<% end %>
ERB
  end

  def test_begin_rescue_ensure
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- begin
  %p a
- rescue FooException => e
  %p b
- ensure
  %p c
HAML
<% begin %>
  <p>a</p>
<% rescue FooException => e %>
  <p>b</p>
<% ensure %>
  <p>c</p>
<% end %>
ERB
  end

  # Regression

  def test_tag_inside_block
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
%table
  - foo.each do
    %tr
HAML
<table>
  <% foo.each do %>
    <tr></tr>
  <% end %>
</table>
ERB
  end

  def test_silent_inside_block_inside_tag
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
%table
  - foo.each do
    - haml_puts "foo"
HAML
<table>
  <% foo.each do %>
    <% haml_puts "foo" %>
  <% end %>
</table>
ERB
  end

  def test_commented_erb_should_not_cause_indentation
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
%title
  html2haml and multiline titles
= # stylesheet_link_tag :first
= stylesheet_link_tag 'another file'
HAML
<title>
  html2haml and multiline titles
</title>
<%=# stylesheet_link_tag :first %>
<%#= stylesheet_link_tag :second %>
<%# stylesheet_link_tag :third %>
<%= stylesheet_link_tag 'another file' %>
ERB
  end

  def test_can_parse_ruby_19_hashes_as_arguments
    erb =  "<%= foobar 'foo', {bar: 'baz'} %>"
    begin
      Html2haml::HTML::ERB.new(erb)
    rescue
      flunk "should not raise an error"
    end
  end

  def test_should_wrap_in_silent
    assert_equal(<<HTML.rstrip, Html2haml::HTML::ERB.new(<<ERB).src)
<haml_silent> some_variable_or_function \n</haml_silent>
HTML
<% some_variable_or_function %>
ERB
  end

  #comment content is removed by erubis
  def test_should_wrap_process_comments_as_empty_lines
    assert_equal(<<HTML.rstrip, Html2haml::HTML::ERB.new(<<ERB).src)
<haml_silent>\n</haml_silent>
HTML
<%# some_variable_or_function %>
ERB
  end

  def test_conditional_structure_in_argument
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
%span{:class => "\#{"active" if condition}"}
HAML
<span class="<%= "active" if condition %>"></span>
HTML
  end

  def test_method_call_without_brackets_in_argument
    assert_equal(<<HAML.rstrip, render_erb(<<HTML))
%span{:class => "\#{call_me maybe}"}
HAML
<span class="<%= call_me maybe %>"></span>
HTML
  end

  def test_multiline_erb_comment
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
- # comment
%p hi
HAML
<%
# comment
-%>
<p>hi</p>
ERB
  end

  ##
  # <%== %> is supposed to be equal to <%= raw %>
  def test_erb_with_double_equals
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
!= link_to "https://github.com/haml/html2haml/issues/44"
HAML
<%== link_to "https://github.com/haml/html2haml/issues/44" %>
ERB
  end

  #https://github.com/haml/html2haml/issues/43
  def test_escaped_ruby_call_when_preceded_by_text
    assert_equal(<<HAML.rstrip, render_erb(<<ERB))
random text
= form_tag(url: sessions_path) do
  = submit_tag "cdcd"
HAML
random text
<%= form_tag(url: sessions_path) do %>
   <%= submit_tag "cdcd" %>
<% end %>
ERB
  end
end
