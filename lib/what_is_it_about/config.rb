# coding: utf-8

require 'yaml'

module WhatIsItAbout
  def self.config
    @@config = Config.new
  end

  class Config
    def initialize(file = "#{Dir.home}/.what_is_it_about")
      @file = file
      @data = File.exist?(file) ? YAML.load_file(file) : {}
    end

    def get(*path)
      data = @data
      path.each do |branch|
        data = data[branch]
        return unless data
      end
      data
    end

    def set(*args)
      val = args.pop
      leaf = args.pop
      data = @data
      args.each do |branch|
        data[branch] ||= {}
        data = data[branch]
      end
      data[leaf] = val
      File.open(@file, 'w') do |f|
        f.puts YAML.dump(@data)
      end
    end
  end
end
