# coding: utf-8

module WhatIsItAbout
  module Report
    class PlainText
      def initialize(summary)
        @summary = summary
      end

      def to_s
        lines = @summary.gem_groups.each_with_object([]) do |(_group, gems), lines|
          gems.each do |gem|
            if gem.added?
              lines << [
                '+',
                gem.name,
                gem.versions[:new],
                gem_source(gem, :new)
              ].join(' ')
            elsif gem.removed?
              lines << [
                '-',
                gem.name,
                gem.versions[:old],
                gem_source(gem, :old)
              ].join(' ')
            elsif gem.changed?
              version_line = "#{gem_source(gem, :old)} => #{gem_source(gem, :new)}"
              lines << [
                'C',
                gem.name,
                version_line
              ].join(' ')
            end
          end
          if gems.first.changed?
            gems.first.commits_log.each do |type, log|
              next unless log
              next if log[:commits].empty?
              padding = ' '*4
              lines << padding + "commits #{type} #{log[:html_url]}"
              padding *= 2
              message_padding = padding * 2
              log[:commits].each do |commit|
                next if commit[:parents].size == 2 # merge
                lines << [
                  padding + commit[:commit][:author][:name],
                  commit[:html_url]
                ].join(' ')
                padded_message = commit[:commit][:message].lines.map do |line|
                  message_padding + line
                end.join('')
                lines << padded_message
              end
            end
          end
        end
        lines.join("\n")
      end

      private

      def gem_source(gem, version)
        case gem.source_types[version]
        when :rubygems
          gem.versions[version]
        when :path
          gem.paths[version]
        when :git
          "#{gem.source_branches[version]}##{gem.source_revisions[version]}"
        else
          raise "Unknown source type for #{gem.inspect}"
        end
      end
    end
  end
end
