# Html2haml

Converts HTML to Haml. This is in the process of being extracted from the Haml 
gem.

## Installation

Add this line to your application's Gemfile:

    gem 'html2haml'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install html2haml

## Usage

See `html2haml --help`:

    Usage: html2haml [options] [INPUT] [OUTPUT]

    Description: Transforms an HTML file into corresponding Haml code.

    Options:
        -e, --erb                        Parse ERb tags.
            --no-erb                     Don't parse ERb tags.
        -r, --rhtml                      Deprecated; same as --erb.
            --no-rhtml                   Deprecated; same as --no-erb.
        -x, --xhtml                      Parse the input using the more strict XHTML parser.
            --html-attributes            Use HTML style attributes instead of Ruby hash style.
        -E ex[:in]                       Specify the default external and internal character encodings.
        -s, --stdin                      Read input from standard input instead of an input file
            --trace                      Show a full traceback on error
            --unix-newlines              Use Unix-style newlines in written files.
        -?, -h, --help                   Show this message
        -v, --version                    Print version
