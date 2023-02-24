#!/usr/bin/env -S ruby --enable=jit

# Run with --help, or -h, to see the options:
#   ./podcast_export -h

require 'fileutils'
require 'cgi'

class PodcastsExport
  def initialize(args = nil)
    raise ('Gems missing, please execute setup.rb') unless sanity_check!
    args_copy = args.dup
    display_help  = args_copy.empty? || !(args_copy.delete('-h') || args_copy.delete('--help')).nil?
    @list_podcasts = !(args_copy.delete('-l') || args_copy.delete('--list')).nil?
    @all_podcasts = !(args_copy.delete('-a') || args_copy.delete('--all')).nil?
    @edit_media_tags = (args_copy.delete('-k') || args_copy.delete('--keep-tags')).nil?
    @podcast_name  = args_copy[0].to_s
    @number_prefix = args_copy[1].to_s.downcase != 'no'
    @output_folder = args_copy[2].to_s
    @podcast_name = nil if (@podcast_name == '') || @all_podcasts
    if @podcast_name
      puts "- Podcast name:'#{@podcast_name}'"
    end
    if @podcast_name || @all_podcasts
      puts "- It will #{'not ' if !@number_prefix}prefix the file names by the episode number."
    end
    if @output_folder.nil? || @output_folder.empty?
      @output_folder = File.expand_path('~/Documents/Podcasts_Export/')
    else
      @output_folder = File.expand_path @output_folder
      puts "- Output folder: '#{@output_folder}'"
    end
    unless @edit_media_tags
      puts '- Keeping the original file media tags'
    end
    if display_help
      puts help_text
    else
      puts '====='
    end
  end

  def do_it!
    if (@podcast_name || @all_podcasts) && !Dir.exist?(@output_folder)
      puts "  * Creating the output folder, '#{@output_folder}'..."
      FileUtils.mkdir_p(@output_folder)
    end
    episodes = get_downloaded_episodes(DATABASE)
    podcast_names = {}
    num_downloaded = 0
    episodes.each do |(author, podcast, title, description, episode_number, pub_year, filename)|
      pub_year = Time.at(pub_year + MACOS_SECS_OFFSET).year if pub_year && pub_year > 0
      # puts "  '#{author}', '#{podcast}', '#{title}', #{episode_number} (#{episode_number.class}), "\
      #      "'#{filename}'"
      # puts("Publication year (#{pub_date.class}): #{pub_date}") if pub_date
      safe_podcast  = safe_for_filename(podcast)
      safe_title    = safe_for_filename(title, remove_final_dots: true)
      # episode_number is Integer or nil:
      safe_number   = "#{episode_number}. " if @number_prefix && episode_number && episode_number > 0
      safe_filename = clean_filename(filename)
      if podcast && !podcast.empty?
        podcast_names[podcast] = podcast_names[podcast] ? (podcast_names[podcast] + 1) : 1
      end
      # puts "safe_filename [#{safe_filename.class}]: '#{safe_filename}'"
      # puts "File.file?(safe_filename) [#{File.file?(safe_filename).class}]: '#{File.file?(safe_filename)}'"
      # puts "@podcast_name [#{@podcast_name.class}] : '#{@podcast_name}'"
      if File.file?(safe_filename) && (@all_podcasts || @podcast_name == podcast)
        # puts "  '#{author}', '#{podcast}', '#{title}', #{episode_number} (#{episode_number.class}), "\
        #      "'#{filename}'"
        file_extension = File.extname(safe_filename)  # .mp3, .mp4,...
        subfolder_array = [ @output_folder, safe_podcast ]
        subfolder_array << pub_year.to_s if pub_year && pub_year > 0
        subfolder = File.join(*subfolder_array)
        unless Dir.exist?(subfolder)
          puts "  * Creating the folder '#{subfolder}'..."
          FileUtils.mkdir_p(subfolder)
        end
        # puts "safe_number: '#{safe_number}', safe_title: '#{safe_title}', "\
        #      "file_extension: '#{file_extension}'"
        filename_only ="#{safe_number}#{safe_title}#{file_extension}"
        output_filename = File.join(subfolder, filename_only)
        # puts "'#{safe_filename}' => '#{output_filename}'"
        puts " -> '#{filename_only}'"
        if @number_prefix && (episode_number.nil? || episode_number <= 0)
          puts '     Note: No episode number in the database'
        end
        # puts "description: '#{description}'"
        FileUtils.cp safe_filename, output_filename
        num_downloaded += 1
        if File.file?(output_filename)
          # puts 'File created!'
          if @edit_media_tags
            # Tagging:
            # puts 'Tagging'
            mime_type = MimeMagic.by_magic File.open(output_filename)
            # puts "mime type: '#{mime_type}'"
            values_to_set = { album: podcast, artist: author, title: title, genre: 'Podcast',
                              comment: description, track: episode_number, year: pub_year }
            # puts "values: #{values_to_set}"
            case mime_type.to_s
              when 'audio/mpeg'
                PodcastsExport.tag_mpeg_file(output_filename, **values_to_set)
              when 'audio/mp4'
                PodcastsExport.tag_mp4_file(output_filename, **values_to_set)
            end
          end
        else
          puts 'Unable to create the file'
          puts
        end
      # else
      #   raise "The file '#{safe_filename}' does not exist!!"
      end
    end
    if num_downloaded > 0
      puts "Downloaded #{num_downloaded} episodes, at '#{@output_folder}'"
    else
      puts 'No episodes downloaded.'
    end
    if @list_podcasts
      if podcast_names.empty?
        puts "No podcasts available:"
      else
        podcast_names_only = podcast_names.keys.sort
        puts '---'
        puts "#{podcast_names_only.size} Podcasts (with the number of episodes available):"
        puts
        podcast_names_only.each{|name| puts "#{name} (#{podcast_names[name]})"}
      end
    end
    # exit(0)
  end
  
  class << self

    def do_it!(args)
      pe = self.new(args)
      pe.do_it!
    end

    # ID3v1 & ID3v2 Tagging:
    def tag_mpeg_file(filename, album: nil, artist: nil, title: nil, genre: nil, comment: nil,
                      track: nil, year: nil)
      to_set = { album: album, artist: artist, title: title, genre: genre,
                 comment: comment }.select{|k,v| !(v.nil? || v == '')}
      to_set[:track] = track if track && track > 0
      to_set[:year] = year if year && year > 0
      if File.file?(filename) && to_set.any?
        TagLib::MPEG::File.open(filename) do |file|
          # ID3v1:
          if file.id3v1_tag?
            tag1 = file.id3v1_tag
          else
            tag1 = file.id3v1_tag(true)
          end
          # ID3v2:
          if file.id3v2_tag?
            tag2 = file.id3v2_tag
          else
            tag2 = file.id3v2_tag(true)
          end
          has_changed = false
          to_set.each do |k, v|
            previous_value1 = tag1.send k
            if previous_value1.nil? || (previous_value1 == '') || (previous_value1 == 0)
              # Note: strings over 30 characters would get truncated for ID3v1
              tag1.send "#{k}=".to_sym, v
              has_changed = true
              # puts "V1 #{k}: #{previous_value1} => #{v}. Changed? #{has_changed}"
            end
            previous_value2 = tag2.send k
            if previous_value2.nil? || (previous_value2 == '') || (previous_value2 == 0) ||
               ((k == :comment) && (previous_value2.size < v.size))
              tag2.send "#{k}=".to_sym, v
              has_changed = true
              # puts "V2 #{k}: [#{previous_value2}] => [#{v}]. Changed? #{has_changed}"
            end
          end
          # Save changes if needed
          file.save if has_changed
        end
      end
    end

    def tag_mp4_file(filename, album: nil, artist: nil, title: nil, genre: nil, comment: nil,
                     track: nil, year: nil)
      to_set = { album: album, artist: artist, title: title, genre: genre,
                 comment: comment }.select{|k,v| !(v.nil? || v == '')}
      to_set[:track] = track if track && track > 0
      to_set[:year] = year if year && year > 0
      if File.file?(filename) && to_set.any?
        TagLib::MP4::File.open(filename) do |file|
          tag = file.tag
          has_changed = false
          to_set.each do |k, v|
            previous_value = tag.send(k) if tag[k.to_s].valid?
            if previous_value.nil? || (previous_value == '') || (previous_value == 0)
              if %i(track year).include?(k)
                tag[k] = TagLib::MP4::Item.from_int(v)
              else
                tag[k] = TagLib::MP4::Item.from_string_list([k])
              end
              has_changed = true
            end
          end
          puts "to_set: #{to_set} --- has_changed? #{has_changed}"
          # TESTING ---
          puts 'MP4 files are not supported at this moment.'
          # file.save if has_changed
        end
      end
    end
  end

  private

  DATABASE = File.expand_path('~/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/'\
                              'Documents/MTLibrary.sqlite')

  # macOS, internally, counts time from Midnight January 1, 2001 UTC.
  #   This is the difference, in seconds with Unix Epoch (since Midnight January 1, 1970 UTC)
  MACOS_SECS_OFFSET = 978_307_200

  QUERY = 'SELECT p.ZAUTHOR, p.ZTITLE, e.ZTITLE, e.ZITEMDESCRIPTION, e.ZEPISODENUMBER, e.ZPUBDATE, '\
          '       e.ZASSETURL FROM ZMTEPISODE e '\
          'JOIN ZMTPODCAST p ON e.ZPODCASTUUID = p.ZUUID '\
          'WHERE ZASSETURL NOTNULL;'

  def get_downloaded_episodes(db_path)
    db = SQLite3::Database.new(db_path)
    return db.execute(QUERY)
  end

  # true if all is OK
  def sanity_check!
    %w(mimemagic sqlite3 taglib).all?{|gem_name| gem_installed?(gem_name)}
  end

  def help_text
    DATA.read
  end

  def gem_installed?(name)
    require name
    true
  rescue LoadError
    false
  end

  def safe_for_filename(name, remove_final_dots: false)
    v = (name || '').to_s.gsub('/', '|').gsub(':', ',').strip
    v = v.gsub(/\.\z/, '') if !v.empty? && remove_final_dots
    v
  end

  def clean_filename(filename)
    new_name = filename.dup
    new_name = new_name[7..-1] if new_name.start_with?('file://')
    CGI.unescape(new_name)
  end
end

PodcastsExport.do_it!(ARGV)

__END__
========================================================
Podcasts Export

  Usage:
    ./podcasts_export [podcast name] [episode number prefix] [download folder] [other options]

  All parameters are optional:
    - podcast name:  Name of a podcast, between commas if it includes spaces (for ex. 'Healthy Hacker').
        It needs to match the name the Apple Podcasts app uses (see the suggestion below).
    - episode number prefix: YES or NO (YES if not present). Prefixes file names by the episode's number.
        Note that in some cases this number is already part of the original episode title, so adding would show it twice (use NO then)
    - download folder: folder (directory) where to download the episode files (if none given, it uses '~/Documents/Podcasts_Export/').
    - Other options (all prefixed by at least one '-' and can be in any order):
      --all or -a: save all downloaded podcast (ignore the [podcast name] given, if any)
      --help or -h: shows this message
      --keep-tags or -k: keeps the original files' content, not trying to "fix" the embedded media tags
      --list or -l: lists podcast names available, with the number of episodes downloaded

  If no parameters are present, if will display this help message (same as the --help option).

  Suggestion: get the name of the podcast you want to save running the program with the '-l' option first, to see which are the actual names.

  Examples:

   ./podcasts_export -h
     it displays this message.
   ./podcasts_export -l
     it list all podcasts available.
   ./podcasts_export 'the Sharp End Podcast'
     Downloads the episodes of 'the Sharp End Podcast'.
   ./podcasts_export -k Systematic
     Downloads the episodes of Systematic, as-is, not editing media tags
   ./podcasts_export Rework NO
     Downloads the episodes of the 'Rework' podcast, not prefixing each file by the episode number.
   ./podcasts_export "Nature Podcast" -l
     Downloads the episodes of the 'Nature Podcast', and also list all podcasts available.
   ./podcasts_export -a
     downloads the episodes available for all podcasts.
   ./podcasts_export '-' NO -a
     downloads all the podcast episodes, not prefixing the files by the episode name.
========================================================
