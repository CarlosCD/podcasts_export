## Podcasts Export

Some time go Apple changed its Podcasts app and removed the option of saving aside audio/video files.
Maybe they will add it back, maybe they will not. This is a small program to save those files aside...

### Setup

This thing runs on macOS and Ruby. It may work in other systems, it may not. Ruby comes pre-installed
in most Mac or Linux machines. You can verify that it is present by running:

    ruby -v

It should show the version of Ruby you have, or err if you've none...

Also it uses a few Ruby libraries (a.k.a. gems), and a media tagging library. You can install those
extra libraries by running the `setup.rb` program from the Terminal (only for mac OS):

    ./setup.rb

It may install Homebrew if you don't have it.

### Run it

First, using the Podcasts app, download the Podcast episodes you want to keep. Then run:

    ./podcasts_export.rb 

It would be always create a folder '~/Documents/Podcasts_Exports' if it doesn't already exist.

If no arguments are passed, I will list the names of the Podcasts where there are episodes downloaded
in the Podcast app.

#### Options

1st argument: the name of the podcast series to download (run the command without arguments to see the
list). If the name includes spaces, then quote the name. For example:

    ./podcasts_export.rb 'Nature Podcast'


The next arguments are probably not so useful:


2nd argument: YES or NO. Whether prefix the name of the file by the episode number (default is YES).

    ./podcasts_export.rb 'Nature Podcast' NO

3rd argument: folder where to save the file(s). If not set, it will use '~/Documents/Podcasts_Exports/'

    ./podcasts_export.rb 'Nature Podcast' YES '~/Documents/temp_folder'

4th argument: The Apple Podcasts database file to be read. This is an internal macOS setting, so it is
probably not a parameter you need to change...

    ./podcasts_export.rb 'Nature Podcast' NO '~/Documents/temp_folder' my_database.db

