## Podcasts Export

### Setup

This thing runs on macOS and Ruby. It may work in other systems, it may not. Ruby comes pre-installed in the last versions of Mac or Linux machines. You can verify that it is present by running:

    ruby -v

It should show the version of Ruby you have, or err if you've none...

Also it uses a few Ruby software libraries (a.k.a. gems). You can install those extra libraries by running the setup.rb program from the Terminal (only for mac OS):

    ./setup.rb

### Run it

First, using the Podcasts app, download the Podcast episodes you want to keep. Then run:

    ./podcasts_export.rb 

If no arguments are passed, I will list the names of the Podcasts where there are episodes downloaded in the Podcast app.
