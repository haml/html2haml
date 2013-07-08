# HTML2Haml Changelog

## 1.1.0

* Switch to using Nokogiri for XML parsing - [Stefan Natchev](https://github.com/snatchev), [Norman Clarke](https://github.com/norman)
  NOTE: This version drops support of JRuby due to behaviour in Nokogiri-jruby.
* Add Ruby 2.0 support - [Yasuharu Ozaki](https://github.com/yasuoza)
* Add option to use Ruby 1.9-style attributes when possible
  (thanks to [Yoshinori Kawasaki](https://github.com/luvtechno) and
  [Alexander Egorov](https://github.com/qatsi)).
* Update dependency versions

## 1.0.1

Rescue from `RubyParser::SyntaxError` in check for valid ruby.

## 1.0.0

* Extracted from Haml and released as an independent gem. For changes from
  previous versions, see the Haml changelog.
