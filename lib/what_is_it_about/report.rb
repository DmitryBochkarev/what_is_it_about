# coding: utf-8

module WhatIsItAbout
  module Report
    class PlainText
      def initialize(summary)
        @summary = summary
      end

      def to_s
        lines = @summary.gems.each_with_object([]) do |gem, lines|
          case
          when gem.added?
            lines << [
              '+',
              gem.name,
              gem.versions[:new],
              gem_source(gem, :new)
            ].join(' ')
          when gem.removed?
            lines << [
              '-',
              gem.name,
              gem.versions[:old],
              gem_source(gem, :old)
            ].join(' ')
          when gem.changed?
            version =
              if gem.version_changed?
                "#{gem.versions[:old]} => #{gem.versions[:new]}"
              else
                gem.versions[:old]
              end
            source =
              if gem.source_changed?
                "#{gem_source(gem, :old)} => #{gem_source(gem, :new)}"
              else
                gem_source(gem, :old)
              end
            lines << [
              'C',
              gem.name,
              version,
              source
            ].join(' ')
            gem.commits_log.each do |type, log|
              next unless log
              next if log[:commits].empty?
              padding = ' '*4
              lines << padding + "commits #{type} #{log[:html_url]}"
              padding *= 2
              message_padding = padding * 2
              log[:commits].each do |commit|
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
          else
            lines << [
              '=',
              gem.name,
              gem.versions[:old],
              gem_source(gem, :old)
            ].join(' ')
          end
        end
        lines.join("\n")
      end

      private

      def gem_source(gem, version)
        case gem.source_types[version]
        when :rubygems
          'rubygems'
        when :path
          gem.paths[version]
        when :git
          "#{gem.source_repositories[version]}##{gem.source_branches[version]}(#{gem.source_revisions[version]})"
        else
          raise "Unknown source type for #{gem.inspect}"
        end
      end
    end
  end
end
