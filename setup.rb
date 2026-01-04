#!/usr/bin/env -S ruby

# Installing the Ruby gems needed (see the Gemfile)...
#   and (perhaps) Homebrew and the taglib brew package.
#
#   if the taglib-ruby gem is not installed, often this doesn't work:
#     gem install taglib-ruby -v 2.0.0
#   Based on the gem's README (at https://github.com/robinst/taglib-ruby):
#   1. Get the TAGLIB_DIR by brew info taglib
#      For example: '/opt/homebrew/Cellar/taglib/2.0.2'
#   2. Then run:
#        TAGLIB_DIR=/opt/homebrew/Cellar/taglib/2.0.2 gem install taglib-ruby -v 2.0.0
#      Or via bundler:
#        TAGLIB_DIR=/opt/homebrew/Cellar/taglib/2.0.2 bundle

class InstallDependencies
  class << self
    def install_all!
      # Is the 'taglib-ruby' gem installed? If not, additional work
      unless gem_present?('taglib-ruby', version: '2.0.0')
        puts "The gem 'taglib-ruby', version '2.0.0' doesn't seem to be installed."
        install_homebrew!
        install_taglib_via_homebrew!
        taglib_dir = get_taglib_dir  # nil if unable to get it
        env_prefix = "TAGLIB_DIR=#{taglib_dir}" if taglib_dir
      end
      system [env_prefix, :bundle].join(' ')
    end

    # Standalone way, not used at this moment:
    def install_tag_lib_gem
      if gem_present?('taglib-ruby')
        puts "The 'taglib-ruby' gem was already installed."
      else
        install_homebrew!
        install_taglib_via_homebrew!
        taglib_dir = get_taglib_dir  # it could be nil
        env_prefix = "TAGLIB_DIR=#{taglib_dir}" if taglib_dir
        puts "Installing the 'taglib-ruby' gem, version 2.0.0..."
        install_success = system "#{env_prefix} gem install taglib-ruby -v 2.0.0"
        unless install_success
          puts "\nUnable to install the Ruby gem taglib-ruby version 2.0.0\n\n" \
               "You could try the following:\n" \
               " 1. Run 'brew info taglib' and find, in its output, the directory where Taglib was installed (probably starting by '/opt/homebrew/')\n" \
               " 2. If, for example this directory is '/opt/homebrew/Cellar/taglib/2.0.2', then run the following command: \n" \
               "    TAGLIB_DIR=/opt/homebrew/Cellar/taglib/2.0.2 gem install taglib-ruby -v 2.0.0"
        end
      end
    end

    private

    def gem_present?(gem_name, version: nil)
      spec = Gem::Specification.find_by_name(gem_name)
      version ? (spec.version == version) : true
    rescue Gem::MissingSpecError
      false
    end

    # Returns nil if the taglib install directory cannot be calculated:
    def get_taglib_dir
      taglib_base_dir = `brew --cellar taglib`.chomp   # '/opt/homebrew/Cellar/taglib'
      taglib_version = `taglib-config --version`.chomp # '1.13.1'
      "#{taglib_base_dir}/#{taglib_version}" unless blank?(taglib_base_dir) || blank?(taglib_version)
    end

    def install_homebrew!
      unless homebrew_installed?
        if command_exists?('curl')
          puts 'Installing HomeBrew...'
          system 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh'
          unless homebrew_installed?
            raise "Unable to install Homebrew...\n" \
                  "Please download it and install it manually, and try again."
          end
        else
          raise "curl is needed to continue... it is strange you didn't seem to have it...\n" \
                "Please download it and install it (for example, from https://curl.se/download.html)"
        end
      end
    end

    def install_taglib_via_homebrew!
      unless homebrew_package_installed?('taglib')
        puts "Installing 'taglib' via Homebrew...."
        system 'brew install taglib'
        unless homebrew_package_installed?('taglib')
          raise "Unable to install 'taglib' via Homebrew...\n" \
                "Please install it manually."
        end
      end
    end

    def homebrew_installed?
      !!command_exists?('brew')
    end

    def homebrew_package_installed?(package_name)
      !!system("brew list #{package_name} &>/dev/null")
    end

    def command_exists?(command)
      !!system("which -s #{command}")
    end

    def blank?(str)
      str.nil? || (str.is_a?(String) && str.empty?)
    end
  end
end

InstallDependencies.install_all!
