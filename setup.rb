#!/usr/bin/env -S ruby --enable=jit

# Installing the Ruby gems needed...

class InstallDependencies
  class << self

    def check_and_install!
      install_needed_gems_maybe
    end

    private

    GEMS_NEEDED = { 'sqlite3' => '1.4.2' }

    def install_needed_gems_maybe
      GEMS_NEEDED.each{|n,v| install_it_maybe(n,v)}
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
  end
end

InstallDependencies.check_and_install!
