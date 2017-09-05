# coding: utf-8

require 'yaml'

module WhatIsItAbout
  def self.config
    @config ||=
      begin
        file = "#{Dir.home}/.what_is_it_about"
        File.exist?(file) ? YAML.load_file(file) : {}
      end
  end

  def self.gem_configs
    @gem_configs ||= (config['gems'] || []).map! do |gem_config|
      if gem_config['name']
        gem_config['name'] = Regexp.compile gem_config['name']
        gem_config
      else
        $stderr.puts "unspecified name in gems config #{gem_config}"
      end
    end.compact
  end

  def self.gem_repo_from_config(name)
    gem_configs.each do |gem_config|
      match = gem_config['name'].match name

      next unless match

      url_template = "https://github.com/#{gem_config['github']}" if gem_config['github']

      unless url_template
        $stderr.puts "github repository not specified for #{gem_config['name']}"
        next
      end

      match.names.each do |var_name|
        url_template.gsub!("${#{var_name}}", match[var_name])
      end

      return url_template
    end

    nil
  end
end
