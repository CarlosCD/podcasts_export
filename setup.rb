#!/usr/bin/env -S ruby

# Installing the Ruby gems needed...
#   and (perhaps) Homebrew and the taglib brew package.

class InstallDependencies
  class << self
    def check_and_install!
      install_needed_gems_maybe
      special_tag_lib_gem_case 
    end

    private

    GEMS_NEEDED = { 'mimemagic' => '0.4.3', 'sqlite3' => '2.2.0' }

    def install_needed_gems_maybe
      GEMS_NEEDED.each{|n,v| install_it_maybe(n,v)}
    end

    def special_tag_lib_gem_case
      if gem_present?('taglib-ruby')
        puts "The 'taglib-ruby' gem was already installed."
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
        #        system 'TAGLIB_DIR=/opt/homebrew/Cellar/taglib/1.13.1 gem install taglib-ruby -v 1.1.3'
        taglib_base_dir = `brew --cellar taglib`.chomp   # '/opt/homebrew/Cellar/taglib'
        taglib_version = `taglib-config --version`.chomp # '1.13.1'
        # taglib-ruby 1.1.3 gem install:
        taglib_dir = "TAGLIB_DIR=#{taglib_base_dir}/#{taglib_version}" unless blank?(taglib_base_dir) || blank?(taglib_version)
        puts "Installing the 'taglib-ruby' gem, version 1.1.3..."
        install_success = system "#{taglib_dir} gem install taglib-ruby -v 1.1.3"
        unless install_success
          puts "\nUnable to install the Ruby gem taglib-ruby version 1.1.3\n\n" \
               "You could try the following:\n" \
               " 1. Run 'brew info taglib' and find, in its output, the directory where Taglib was installed (probably starting by '/opt/homebrew/')\n" \
               " 2. If, for example this directory is '/opt/homebrew/Cellar/taglib/1.13.1', then run the following command: \n" \
               "    TAGLIB_DIR=/opt/homebrew/Cellar/taglib/1.13.1 gem install taglib-ruby -v 1.1.3"
        end
      end
    end

    def install_it_maybe(gem_name, version)
      if gem_present?(gem_name)
        puts "The '#{gem_name}' gem, version #{version}, was already installed."
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
        puts 'Homebrew was already installed'
        # system 'brew update; brew upgrade; brew cleanup'
      elsif system 'which -s curl'
        puts 'Installing HomeBrew...'
        system 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh'
      else
        raise "curl is needed to continue... it is strange you didn't seem to have it... "\
              "Please download it and install it (for example, from https://curl.se/download.html)"
      end
    end

    def blank?(str)
      str.nil? || (str.is_a?(String) && str.empty?)
    end
  end
end

InstallDependencies.check_and_install!
