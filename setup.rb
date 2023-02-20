#!/usr/bin/env -S ruby --enable=jit

# Installing the Ruby gems needed...
#   and (perhaps) Homebrew and the taglib brew package.

class InstallDependencies
  class << self

    def check_and_install!
      install_needed_gems_maybe
      special_tag_lib_gem_case 
    end

    private

    GEMS_NEEDED = { 'mimemagic' => '0.4.3', 'sqlite3' => '1.4.2' }

    def install_needed_gems_maybe
      GEMS_NEEDED.each{|n,v| install_it_maybe(n,v)}
    end

    def special_tag_lib_gem_case
      if gem_present?('taglib-ruby')
        puts "You already had the 'taglib-ruby' gem installed."
      else
        install_homebrew_maybe
        if system "brew list taglib &>/dev/null"
          puts "You already had the 'taglib' Homebrew package installed."
        else
          puts "Installing 'taglib' via Homebrew...."
          system 'brew install taglib'
        end
        # If doing just this:
        #     system 'gem install taglib-ruby -v 1.1.0'
        #   doesn't work, try (README at https://github.com/robinst/taglib-ruby):
        #     1. Get the TAGLIB_DIR by doing brew info taglib
        #.        For example: '/opt/homebrew/Cellar/taglib/1.13'
        #     2. Then run this:
        #        system 'TAGLIB_DIR=/opt/homebrew/Cellar/taglib/1.13 gem install taglib-ruby -v 1.1.0'
        taglib_info = (`brew info taglib`).split("\n")
        taglib_dir = taglib_info[taglib_info.index('https://taglib.org/') + 1].split.first
        # Gem install:
        taglib_dir = 'TAGLIB_DIR=' + taglib_dir unless taglib_dir.empty?
        puts "Installing the 'taglib-ruby' gem..."
        system "#{taglib_dir} gem install taglib-ruby -v 1.1.3"
      end
    end

    def install_it_maybe(gem_name, version)
      if gem_present?(gem_name)
        puts "You already had the '#{gem_name}' gem installed."
      else
        puts "Installing the '#{gem_name}' gem (version #{version}) ..."
        command = "gem install #{gem_name}"
        system "gem install #{gem_name} -v #{version}"
      end
    end

    def gem_present?(gem_name)
      Gem::Specification.find_by_name(gem_name)
      true
    rescue Gem::MissingSpecError
      false
    end

    def install_homebrew_maybe
      if system 'which -s brew'
        puts 'Homebrew is already installed'
        # system 'brew update; brew upgrade; brew cleanup'
      elsif system 'which -s curl'
        puts 'Installing HomeBrew...'
        system 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh'
      else
        raise "curl is needed to continue... it is strange you didn't seem to have it... "\
              "Please download it and install it (for example, from https://curl.se/download.html)"
      end
    end
  end
end

InstallDependencies.check_and_install!
