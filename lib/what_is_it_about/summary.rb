# coding: utf-8

module WhatIsItAbout
  class Summary
    def initialize(old_gemfile_lock_content, new_gemfile_lock_content)
      @compare_cache = {}
      @old_definition = definition(old_gemfile_lock_content)
      @new_definition = definition(new_gemfile_lock_content)
    end

    def gems
      @gems ||=
        begin
          gem_names = (@old_definition.specs + @new_definition.specs).map(&:name).uniq.sort
          gem_names.map { |name| gem_summary(name)}
        end
    end

    def gem_groups
      @gem_groups = gems.group_by do |gem|
        gem.group || gem.name
      end
    end

    private

    attr_reader :compare_cache

    def definition(gemfile_lock_content)
      Bundler::LockfileParser.new(gemfile_lock_content)
    end

    def gem_summary(name)
      old_spec = @old_definition.specs.find { |spec| spec.name == name }
      new_spec = @new_definition.specs.find { |spec| spec.name == name }
      GemSummary.new(old_spec, new_spec, compare_cache: compare_cache)
    end
  end
end
