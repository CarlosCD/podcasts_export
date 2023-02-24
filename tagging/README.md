## Podcasts Export - Misc MPEG tagging utilities

These is some simple utility I wrote when I was looking for the embedded data (tags) in media files. It allows to see
which tags are present in a media file (`.mp3`, `.mpg`, `mpeg`, ...) of the type 'audio/mpeg`. So far I didn't find
much support for videos or mp4 formats... but this is a moving target.

### About media tags

In audio podcasts is common to include episode notes in embedded tags, like a podcast description, useful links,
author, etc. There are different de facto standards, each one with their limitations, and different software support.

Some of those tags are text, using a particular character encoding, not all use UTF-8 or Unicode, so some cases
non-latin characters could be lost. Also, in some cases, the text is written to be displayed in a web page, so it
includes HTML tags as part of the text.

The Apple podcasts app seems to take some information from the file and add it to its database. It also keeps in the
database other information from its download process. When storing the media file, the app also changes the its name,
using an internal code ID, keeping the original file name only in the database.

For these reasons, the export program renames the files and tries to normalize the tags, strip HTML, ...

I added an option to the `podcasts_export` to export the files "as is", without tag changes, which is probably the way
it was published by the original author (run the help option for details). On my tests I saw less details in the
original embedded data, than what was in Apple's Podcast database, so this option may not be so useful.

I have not added an option to keep the internal Podcast App file name (not renaming it), just because I don't find it
so useful.

### The test_id3 tool

This tool, given a media file (song, podcast, ...), shows you the embedded tags for different standards.

Run it by passing the name of a file, for a given media file, including the path to get to it. For example
`~/Documents/the_song_of_my_people.mp3`:

    tagging/test_id3.rb "~/Documents/the_song_of_my_people.mp3"

It also, if possible, extracts the embedded image, if there is any, as a file name "test_img.???" (the extension
depends of the image type).
