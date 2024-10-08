# encoding: UTF-8
require 'test_helper'

class Html2HamlTest < Minitest::Unit::TestCase
  def test_empty_render_should_remain_empty
    assert_equal '', render('')
  end

  def test_doctype
    assert_equal '!!!', render("<!DOCTYPE html>")
    assert_equal '!!! 1.1', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">')
    assert_equal '!!! Strict', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">')
    assert_equal '!!! Frameset', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">')
    assert_equal '!!! Mobile 1.2', render('<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">')
    assert_equal '!!! Basic 1.1', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">')
    assert_equal '!!!', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">')
    assert_equal '!!! Strict', render('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">')
    assert_equal '!!! Frameset', render('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">')
    assert_equal '!!!', render('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">')
  end

  def test_id_and_class_should_be_removed_from_hash
    assert_equal '%span#foo.bar', render('<span id="foo" class="bar"> </span>')
  end

  def test_no_tag_name_for_div_if_class_or_id_is_present
    assert_equal '#foo', render('<div id="foo"> </div>')
    assert_equal '.foo', render('<div class="foo"> </div>')
  end

  def test_multiple_class_names
    assert_equal '.foo.bar.baz', render('<div class=" foo  bar  baz "> </div>')
  end

  def test_should_have_pretty_attributes
    assert_equal('%input{:name => "login", :type => "text"}/',
      render('<input type="text" name="login" />'))
    assert_equal('%meta{:content => "text/html", "http-equiv" => "Content-Type"}/',
      render('<meta http-equiv="Content-Type" content="text/html" />'))
  end

  def test_should_have_html_style_attributes
    assert_equal('%input(name="login" type="text")/',
      render('<input type="text" name="login" />', :html_style_attributes => true))
    assert_equal('%meta(content="text/html" http-equiv="Content-Type")/',
      render('<meta http-equiv="Content-Type" content="text/html" />', :html_style_attributes => true))
  end

  def test_should_have_ruby_19_hash_style_attributes
    assert_equal('%input{name: "login", type: "text"}/',
      render('<input type="text" name="login" />', :ruby19_style_attributes => true))
    assert_equal('%meta{content: "text/html", "http-equiv" => "Content-Type"}/',
      render('<meta http-equiv="Content-Type" content="text/html" />', :ruby19_style_attributes => true))
  end

  def test_should_have_attributes_without_values
    assert_equal('%input{:disabled => "disabled"}/', render('<input disabled>'))
  end

  def test_class_with_dot_and_hash
    assert_equal('%div{:class => "foo.bar"}', render("<div class='foo.bar'></div>"))
    assert_equal('%div{:class => "foo#bar"}', render("<div class='foo#bar'></div>"))
    assert_equal('.foo.bar{:class => "foo#bar foo.bar"}', render("<div class='foo foo#bar bar foo.bar'></div>"))
  end

  def test_id_with_dot_and_hash
    assert_equal('%div{:id => "foo.bar"}', render("<div id='foo.bar'></div>"))
    assert_equal('%div{:id => "foo#bar"}', render("<div id='foo#bar'></div>"))
  end

  def test_interpolation
    assert_equal('Foo \#{bar} baz', render('Foo #{bar} baz'))
  end

  def test_interpolation_in_attrs
    assert_equal('%p{:foo => "\#{bar} baz"}', render('<p foo="#{bar} baz"></p>'))
  end

  def test_cdata
    assert_equal(<<HAML.strip, render(<<HTML))
%p
  :cdata
    <a foo="bar" baz="bang">
    <div id="foo">flop</div>
    </a>
HAML
<p><![CDATA[
  <a foo="bar" baz="bang">
    <div id="foo">flop</div>
  </a>
]]></p>
HTML
  end

  def test_self_closing_tag
    assert_equal("%img/", render("<img />"))
  end

  def test_inline_text
    assert_equal("%p foo", render("<p>foo</p>"))
  end

  def test_inline_comment
    assert_equal("/ foo", render("<!-- foo -->"))
    assert_equal(<<HAML.strip, render(<<HTML))
/ foo
%p bar
HAML
<!-- foo -->
<p>bar</p>
HTML
  end

  def test_non_inline_comment
    assert_equal(<<HAML.rstrip, render(<<HTML))
/
  Foo
  Bar
HAML
<!-- Foo
Bar -->
HTML
  end

  def test_non_inline_text
    assert_equal(<<HAML.rstrip, render(<<HTML))
%p
  foo
HAML
<p>
  foo
</p>
HTML
    assert_equal(<<HAML.rstrip, render(<<HTML))
%p
  foo
HAML
<p>
  foo</p>
HTML
    assert_equal(<<HAML.rstrip, render(<<HTML))
%p
  foo
HAML
<p>foo
</p>
HTML
  end

  def test_script_tag
    assert_equal(<<HAML.rstrip, render(<<HTML))
:javascript
  function foo() {
      return "12" & "13";
  }
HAML
<script type="text/javascript">
    function foo() {
        return "12" & "13";
    }
</script>
HTML
  end

  def test_script_tag_with_html_escaped_javascript
    assert_equal(<<HAML.rstrip, render(<<HTML))
:javascript
  function foo() {
      return "12" & "13";
  }
HAML
<script type="text/javascript">
    function foo() {
        return "12" &amp; "13";
    }
</script>
HTML
  end

  def test_script_tag_with_cdata
    assert_equal(<<HAML.rstrip, render(<<HTML))
:javascript
  function foo() {
    return "&amp;";
  }
HAML
<script type="text/javascript">
  <![CDATA[
    function foo() {
      return "&amp;";
    }
  ]]>
</script>
HTML
  end

  def test_pre
    assert_equal(<<HAML.rstrip, render(<<HTML))
%pre
  :preserve
    foo
      bar
    baz
HAML
<pre>foo
  bar
baz</pre>
HTML
  end

  def test_pre_code
    assert_equal(<<HAML.rstrip, render(<<HTML))
%pre
  %code
    :preserve
      foo
        bar
      baz
HAML
<pre><code>foo
  bar
baz</code></pre>
HTML
  end

  def test_code_without_pre
    assert_equal(<<HAML.rstrip, render(<<HTML))
%code
  foo
  bar
  baz
HAML
<code>foo
  bar
baz</code>
HTML
  end

  def test_conditional_comment
    assert_equal(<<HAML.rstrip, render(<<HTML))
/[if foo]
  bar
  baz
HAML
<!--[if foo]>
  bar
  baz
<![endif]-->
HTML
  end

  def test_style_to_css_filter
    assert_equal(<<HAML.rstrip, render(<<HTML))
:css
  foo {
      bar: baz;
  }
HAML
<style type="text/css">
    foo {
        bar: baz;
    }
</style>
HTML
  end

  def test_style_to_css_filter_with_following_content
    assert_equal(<<HAML.rstrip, render(<<HTML))
%head
  :css
    foo {
        bar: baz;
    }
%body Hello
HAML
<head>
  <style type="text/css">
      foo {
          bar: baz;
      }
  </style>
</head>
<body>Hello</body>
HTML
  end

  def test_style_to_css_filter_with_no_content
    assert_equal(<<HAML.rstrip, render(<<HTML))
:css
HAML
<style type="text/css"> </style>
HTML
    assert_equal(<<HAML.rstrip, render(<<HTML))
:css
HAML
<style type="text/css"></style>
HTML
  end

  def test_filter_with_inconsistent_indentation
    assert_equal(<<HAML.rstrip, render(<<HTML))
:css
  foo {
      badly: indented;
  }
HAML
<style type="text/css">
  foo {
    badly: indented;
}
</style>
HTML
  end

  def test_inline_conditional_comment
    assert_equal(<<HAML.rstrip, render(<<HTML))
/[if foo] bar baz
HAML
<!--[if foo]> bar baz <![endif]-->
HTML
  end

  def test_minus_in_tag
    assert_equal("%p - foo bar -", render("<p>- foo bar -</p>"))
  end

  def test_equals_in_tag
    assert_equal("%p = foo bar =", render("<p>= foo bar =</p>"))
  end

  def test_hash_in_tag
    assert_equal("%p # foo bar #", render("<p># foo bar #</p>"))
  end

  def test_comma_post_tag
    assert_equal(<<HAML.rstrip, render(<<HTML))
#foo
  %span> Foo
  ,
  %span bar
  Foo
  %span> bar
  ,
  %span baz
HAML
<div id="foo">
  <span>Foo</span>, <span>bar</span>
  Foo<span>bar</span>, <span>baz</span>
</div>
HTML
  end

  def test_comma_post_tag_with_text_before
    assert_equal(<<HAML.rstrip, render(<<HTML))
#foo
  Batch
  = succeed "," do
    %span Foo
  %span Bar
HAML
<div id="foo">
  Batch
  <span>Foo</span>, <span>Bar</span>
</div>
HTML
  end

  def test_haml_tags_should_be_on_new_line_after_tag_with_blank_content
    xml  = "<weight> </weight>\n<pages>102</pages>"
    haml = "%weight\n%pages 102"
    assert_equal haml, render(xml)
  end

  # Encodings

  def test_encoding_error
    render("foo\nbar\nb\xFEaz".force_encoding("utf-8"))
    assert(false, "Expected exception")
  rescue Haml::Error => e
    assert_equal(3, e.line)
    assert_match(/Invalid UTF-8 character/, e.message)
  end

  def test_ascii_incompatible_encoding_error
    template = "foo\nbar\nb_z".encode("utf-16le")
    template[9] = "\xFE".force_encoding("utf-16le")
    render(template)
    assert(false, "Expected exception")
  rescue Haml::Error => e
    assert_equal(3, e.line)
    assert_match(/Invalid UTF-16LE character/, e.message)
  end

  # Regression Tests

  def test_xhtml_strict_doctype
    assert_equal('!!! Strict', render(<<HTML))
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
HTML
  end

  def test_html_document_without_doctype
    assert_equal(<<HAML.rstrip, render(<<HTML))
!!!
%html
  %head
    %meta{:content => "text/html; charset=UTF-8", "http-equiv" => "Content-Type"}/
    %title Hello
  %body
    %p Hello
HAML
<html>
<head>
  <title>Hello</title>
</head>
<body>
  <p>Hello</p>
</body>
</html>
HTML
  end

end
