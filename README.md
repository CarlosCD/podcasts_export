## Podcasts Export

Some time go Apple changed its Podcasts app and removed the option for saving aside audio/video files.
Maybe they will add it back, maybe they will have it when you read this, maybe they will never do it...
This is a small command-line program to save those files aside...

### Setup

This thing runs on macOS and uses Ruby. It may work in other systems, it may not. Ruby comes
pre-installed in most Mac or Linux machines. You can verify that it is present by running:

    ruby -v

It should show the version of Ruby you have, or err if you've none...

Also it uses a few Ruby libraries (a.k.a. gems), and a media tagging library. You can install those
extra libraries by running the `setup.rb` program from the Terminal (in mac OS):

    ./setup.rb

It may install Homebrew if you don't have it.

### Run it

First, using the Apple Podcasts app, download the Podcast episodes you want to keep.

Then run from the Terminal:

    ./podcasts_export.rb 

If no arguments are passed, it will show you a help message with all the options.

It would also create a folder '~/Documents/Podcasts_Exports' if it doesn't exist (other folders could
be used, the help message will tell you how to do so).
