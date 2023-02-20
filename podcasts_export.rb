#!/usr/bin/env -S ruby --enable=jit

# 3 possible arguments (all optional):
#   1. Name of the podcast, between commas if includes spaces (for ex. 'Crypto-Gram Security Podcast')
#   2. Whether to prefix the files by the episode name (yes, unless specifieds NO)
#   3. The output folder
#
# If no arguments, returns the list of Podcast that have downloads in the app
#
# Example:
#   ./podcast_export 'Crypto-Gram Security Podcast' NO

require 'fileutils'
require 'cgi'

class PodcastsExport
  def initialize(args = nil)
    raise ('Gems missing, please execute setup.rb') unless sanity_check!
    @podcast_name  = args[0].to_s
    @number_prefix = args[1].to_s.downcase != 'no'
    @output_folder = args[2].to_s
    if @podcast_name && !@podcast_name.empty?
      puts "- Podcast name:      '#{@podcast_name}'"\
           "- Number prefix?:    #{@number_prefix}"
    end
    if @output_folder.nil? || @output_folder.empty?
      @output_folder = File.expand_path('~/Documents/Podcasts_Export/')
    else
      @output_folder = File.expand_path @output_folder
      puts "- Output folder:   '#{@output_folder}'"
    end
    puts '==='
  end

  def do_it!
    unless Dir.exist?(@output_folder)
      puts "Creating the output folder, '#{@output_folder}'..."
      FileUtils.mkdir_p(@output_folder)
    end
    podcast_subfolders = []
    episodes = get_downloaded_episodes(DATABASE)
    podcast_names = []
    num_downloaded = 0
    episodes.each do |(author, podcast, title, description, episode_number, pub_year, filename)|
      pub_year = Time.at(pub_year + MACOS_SECS_OFFSET).year if pub_year && pub_year > 0
      # puts "'#{author}', '#{podcast}', '#{title}', #{episode_number} (#{episode_number.class}), "\
      #.     "'#{filename}'"
      # puts("Publication year (#{pub_date.class}): #{pub_date}") if pub_date
      safe_podcast  = safe_for_filename(podcast)
      safe_title    = safe_for_filename(title, remove_final_dots: true)
      # episode_number is Integer or nil:
      safe_number   = "#{episode_number}. " if @number_prefix && episode_number && episode_number > 0
      safe_filename = clean_filename(filename)
      podcast_names << podcast if podcast && !podcast.empty?
      if File.file?(safe_filename) && (@podcast_name.nil? || @podcast_name == podcast)
        file_extension = File.extname(safe_filename)  # .mp3, .mp4,...
        subfolder_array = [ @output_folder, safe_podcast ]
        subfolder_array << pub_year.to_s if pub_year && pub_year > 0
        subfolder = File.join(*subfolder_array)
        unless Dir.exist?(subfolder)
          puts "Creating the output folder, '#{subfolder}'"
          FileUtils.mkdir_p(subfolder)
            podcast_subfolders << subfolder
        end
        # puts "safe_number: '#{safe_number}', safe_title: '#{safe_title}', "\
        #.     "file_extension: '#{file_extension}'"
        filename_only ="#{safe_number}#{safe_title}#{file_extension}"
        output_filename = File.join(subfolder, filename_only)
        # puts "'#{safe_filename}' => '#{output_filename}'"
        puts " -> '#{filename_only}'"
        # puts "description: '#{description}'"
        FileUtils.cp safe_filename, output_filename
        num_downloaded += 1
        # Tagging:
        if File.file?(output_filename)
          puts 'File created!'
          values_to_set = { album: podcast, artist: author, title: title, genre: 'Podcast',
                            comment: description, track: episode_number, year: pub_year }
          mime_type = MimeMagic.by_magic File.open(output_filename)
          # puts "mime type: #{mime_type} - values: #{values_to_set}"
          case mime_type.to_s
            when 'audio/mpeg'
              PodcastsExport.tag_mpeg_file(output_filename, **values_to_set)
            when 'audio/mp4'
              PodcastsExport.tag_mp4_file(output_filename, **values_to_set)
          end
        end
        puts
      # else
      #   raise "The file '#{safe_filename}' does not exist!!"
      end
    end
    if num_downloaded > 0
      puts "Downloaded #{num_downloaded} episodes."
    else
      puts 'No episodes downloaded.'
      if podcast_names.empty?
        puts "No podcasts available:"
      else
        podcast_names = podcast_names.uniq.sort
        puts '---'
        puts "Podcasts available (#{podcast_names.size}):"
        podcast_names.each{|n| puts "#{n}"}
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
              # Note: strings over 30 characters would get truncated for ID3v1
              tag2.send "#{k}=".to_sym, v
              has_changed = true
              # puts "V2 #{k}: #{previous_value2} => #{v}. Changed? #{has_changed}"
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
          exit(0)  ## TESTING
          file.save if has_changed
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
