#!/usr/bin/env -S ruby --enable=jit

require 'mimemagic'
require 'taglib'
require_relative 'frame_ids.rb'

class TestId3
  def initialize(args = [])
    filename = ''
    error_message  = nil
    if args.is_a?(Array) && args.any?
      # filename = File.expand_path(args.collect(&:to_s).join(' ').strip)
      filename = File.expand_path(args[0].to_s.strip)
      unless File.file?(filename)
        error_message = "The file '#{filename}' does not exist!"
        filename = ''
      end
    end
    if filename.empty?
      error_message ||= 'A file name should be passed as an Argument!'
      puts error_message
      exit(0)
    else
      puts "1. File: '#{filename}'"
      # filename = File.join(File.dirname(__FILE__), filename)
      # puts "   File: '#{filename}'"
      mime_type = MimeMagic.by_magic File.open(filename)
      # puts "- DEBUG: Mime type (#{mime_type.class}): '#{mime_type}'"
      puts "2. Mime type: '#{mime_type}'"
      # id3_tags = Id3Tags.read_tags_from filename
      klass = nil
      case mime_type.to_s
        when 'audio/mpeg' then klass = TagLib::MPEG::File
        when 'audio/mp4'  then klass = TagLib::MP4::File
      end
      if klass
        klass.open(filename) do |file|
          # puts "- DEBUG: Audio properties: #{file.audio_properties.inspect}"
          tag = file.tag
          # puts "- DEBUG: Tag object: #{file.tag.inspect}"
          if klass == TagLib::MPEG::File
            has_id3v1_tags = file.id3v1_tag?
            puts "3. #{has_id3v1_tags ? 'Includes' : 'No'} ID3v1 tags"
            if has_id3v1_tags
              puts '   (Note: ID3v1 has very small size limits (30 characters). Some data may have been truncated)'
              v1tag = file.id3v1_tag
              # puts "- DEBUG: id3v1_tag: #{v1tag.inspect}"
              tags = {}
              %i(album artist title genre comment).collect{|m| v = (v1tag.send m); tags[m] = v unless v.empty? }
              %i(track year).collect{|m| v = (v1tag.send m); tags[m] = v if v > 0 }
              puts "   3a. tags v1: #{tags.inspect}"
              puts("   3b. comment: '#{v1tag.comment}'") unless v1tag.comment.empty?
            end
            has_id3v2_tags = file.id3v2_tag?
            puts "4. #{has_id3v2_tags ? 'Includes' : 'No'} ID3v2 tags"
            if has_id3v2_tags
              v2tag = file.id3v2_tag
              # puts "- DEBUG: id3v1_tag: #{v1tag}"
              # puts "- DEBUG: id3v2_tag: #{v2tag}"
              tags = {}
              %i(album artist title genre comment).collect{|m| v = (v2tag.send m); tags[m] = v unless v.empty? }
              %i(track year).collect{|m| v = (v2tag.send m); tags[m] = v if v > 0 }
              puts '   4a. tags v2:'
              tags.each do |name, value|
                v = value.is_a?(String) ? "'#{value}'" : value
                puts "       #{name}: #{v}"
              end
              # puts "- DEBUG: tags frames: #{v2tag.frame_list.inspect}"
              frame_ids = v2tag.frame_list.collect(&:frame_id).sort
              puts "   4c. Existing tags frames (#{v2tag.frame_list.size}):"
              frame_ids.each do |f_id|
                puts "       #{f_id}: '#{FRAME_IDS[f_id.to_sym]}'"
              end
              puts '   4d. tags frames candidates for comments/description:'
              comment_frames = []
              frame_ids.select{|id| id.start_with?('T')}.
                        collect{|id| v2tag.frame_list(id)}.
                        flatten.
                        collect do |f|
                          list = tf.field_list
                          list = list[0] if list.size == 1
                          comment_frames << { FRAME_IDS[tf.frame_id.to_sym] => list }
                        end
              comment_frames.each do |h|
                h.each do |k,v|
                  puts "       #{k}: '#{v}'"
                end
              end
              # Test: if it includes an image, extract it and display it (Preview app):
              if frame_ids.include?('APIC')
                pic_frame = v2tag.frame_list('APIC')[0]
                # puts "- DEBUG: APIC frame 1: #{pic_frame.class}: #{pic_frame.inspect}"
                pic_mime_type = pic_frame.mime_type
                # puts "- DEBUG: APIC frame 1 mime type: #{pic_mime_type}"
                pic_mime_type = 'image/jpeg' if pic_mime_type == 'image/jpg'
                # puts "- DEBUG: APIC frame 1 mime type: #{pic_mime_type}"
                # puts "- DEBUG: MimeMagic::TYPES[pic_mime_type]: #{MimeMagic::TYPES[pic_mime_type]}"
                pic_extension = MimeMagic::TYPES[pic_mime_type]&.first&.first
                pic_filename = "test_img.#{pic_extension}"
                File.binwrite(pic_filename, pic_frame.picture)
                # Opes the file in Preview:
                system "open #{pic_filename}"
              end
            end
            # # Test to write tags
            # if !has_id3v1_tags && filename == './The New York Times-The Daily-Year in Sound.mp3'
            #   puts 'Especial case found!'
            #   author  = 'The New York Times'
            #   podcast = 'The Daily'
            #   title   = 'Year in Sound'
            #   v1tag = file.id3v1_tag(true)
            #   v1tag.artist = author
            #   v1tag.album  = podcast
            #   v1tag.title  = title
            #   file.save
            # end
          else # TagLib::MP4::File
            properties = %i(album artist comment genre title track year)
            data = properties.collect{|p| v = tag.send(p); [p.to_s, v]}.
                              select{|p,v| v && (!v.is_a?(String) || !v.empty?) && tag[p].valid?}
            if data.empty?
              puts 'No data'
            else
              data.each do |p,v|
                puts "   #{p}: #{v}"
              end
            end
          end
        end
      else
        puts '3. Unknown file type'
        exit(0)
      end
    end
  end

  def do_it!
  end

  def self.do_it!(args)
    t = self.new(args)
    t.do_it!
  end
end

TestId3.do_it!(ARGV)
