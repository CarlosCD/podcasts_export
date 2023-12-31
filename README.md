## Podcasts Export
![GitHub top language](https://img.shields.io/github/languages/top/CarlosCD/podcasts_export?color=red&style=plastic)
![GitHub](https://img.shields.io/github/license/CarlosCD/podcasts_export?style=plastic)

Some time ago Apple changed its Podcasts app and removed the option for saving aside audio/video files.
Maybe they will add it back, maybe they will have it when you read this, maybe they will never do it...
This is a small command-line program to save those files aside...

### Setup

This thing runs on macOS and uses Ruby. It may work in other systems, it may not. Ruby comes
pre-installed in most Mac or Linux machines. You can verify that it is present by running in the Terminal app:

    ruby -v

It should show the version of Ruby you have, or err if you've none...

Also it uses a few Ruby libraries (a.k.a. gems), and a media tagging library. You can install those
extra libraries by running the `setup.rb` program from the Terminal (in mac OS):

    ./setup.rb

It may install Homebrew if you don't have it.

In my particular case, I use [RVM: Ruby Version Manager](https://rvm.io/) to manage my Rubies (allows to
have different versions of Ruby and switch among them, and also add/remove gems easily). You don't need to
use it, but if you do, I have it configured for `Ruby 3.3.0@general`, if you want a different settings, you
may want to change it at the files `.ruby-version` & `.ruby-gemset` (hidden in Unix). For details see RVM's
website ([RVM Project Workflow](https://rvm.io/workflow/projects#project-file-ruby-version)).

### Run it

First, using the Apple Podcasts app, download the Podcast episodes you want to keep.

Then run from the Terminal:

    ./podcasts_export.rb 

If no arguments are passed, it will show you a help message with all the options.

### On embedded media tags

When looking into the standards used for file embedded media tags I wrote a very simple test utility to inspect audio
files. If of interests, [here it is](tagging/).
