#!/usr/bin/env -S ruby --enable=jit

# Returns the list of Podcast that have downloads in the app

class PodcastsExport
  def initialize(args = nil)
    @db_path = File.expand_path('~/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Documents/MTLibrary.sqlite')
    raise ('Gems missing, please execute setup.rb') unless sanity_check!
  end

  def do_it!
    episodes = get_downloaded_episodes(@db_path)
    podcast_names = []
    episodes. #select{|episode| episode.is_a?(Array) && episode.compact.size == 5}.
             each do |(author, podcast, title, description, episode_number, pub_year, filename)|
      podcast_names << podcast if podcast && !podcast.empty?
    end
    if podcast_names.empty?
      puts "No podcasts available:"
    else
      podcast_names = podcast_names.uniq.sort
      puts "Podcasts available (#{podcast_names.size}):"
      podcast_names.each{|n| puts "#{n}"}
    end
  end
  
  class << self

    def do_it!(args)
      pe = self.new(args)
      pe.do_it!
    end

  end

  private

  QUERY = 'SELECT p.ZAUTHOR, p.ZTITLE, e.ZTITLE, e.ZITEMDESCRIPTION, e.ZEPISODENUMBER, e.ZPUBDATE, e.ZASSETURL FROM ZMTEPISODE e '\
          'JOIN ZMTPODCAST p ON e.ZPODCASTUUID = p.ZUUID '\
          'WHERE ZASSETURL NOTNULL;'

  def get_downloaded_episodes(db_path)
    db = SQLite3::Database.new(db_path)
    return db.execute(QUERY)
  end

  # true if all is OK
  def sanity_check!
    gem_installed?('sqlite3')
  end

  def gem_installed?(name)
    require name
    true
  rescue LoadError
    false
  end
end

PodcastsExport.do_it!(ARGV)
