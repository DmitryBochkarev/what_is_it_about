module WhatIsItAbout
  class GemSummary
    GITHUB_RX = %r{github\.com}
    REPO_RX = %r{[/:](?<user>[\w-]+)/(?<repo>[\w-]+)(?<suffix>\.git)?}

    def initialize(old_spec, new_spec, compare_cache:)
      @compare_cache = compare_cache
      @spec = {
        old: old_spec,
        new: new_spec
      }
    end

    def name
      @spec.values.compact[0].name
    end

    def added?
      @spec[:old].nil?
    end

    def removed?
      @spec[:new].nil?
    end

    def changed?
      version_changed? || source_changed?
    end

    def version_changed?
      versions.values.uniq.size != 1
    end

    def versions
      spec_map do |_v, spec|
        spec.version.to_s
      end
    end

    def source_changed?
      source_type_changed? || path_changed? || source_repository_changed? || source_branch_changed? || source_revision_changed?
    end

    def source_type_changed?
      source_types.values.uniq.size != 1
    end

    def source_types
      spec_map do |_v, spec|
        case spec.source
        when Bundler::Source::Git
          :git
        when Bundler::Source::Path
          :path
        when Bundler::Source::Rubygems
          :rubygems
        end
      end
    end

    def path_changed?
      paths.values.uniq.size != 1
    end

    def paths
      spec_map do |_v, spec|
        spec.source.path.to_s if spec.source.class == Bundler::Source::Path
      end
    end

    def source_repository_changed?
      source_repositories.values.uniq.size != 1
    end

    def source_repositories
      spec_map do |_v, spec|
        spec.source.uri if spec.source.class == Bundler::Source::Git
      end
    end

    def source_branch_changed?
      source_branches.values.uniq.size != 1
    end

    def source_branches
      spec_map do |_v, spec|
        next unless spec.source.class == Bundler::Source::Git
        if spec.source.branch.to_s.empty?
          'master'
        else
          spec.source.branch
        end
      end
    end

    def source_revision_changed?
      source_revisions.values.uniq.size != 1
    end

    def source_revisions
      spec_map do |_v, spec|
        spec.source.revision if spec.source.class == Bundler::Source::Git
      end
    end

    def commits_log
      return unless changed?

      @commits_log ||= {
        removed: removed_compare,
        added: added_compare
      }
    end

    def group
      commits_log && commits_log[:added] && commits_log[:added][:commits].any? && commits_log[:added][:html_url]
    end

    private

    attr_reader :compare_cache

    def spec_map(&block)
      @spec.map do |k, spec|
        v = block.call(k, spec) if spec
        [k, v]
      end.to_h
    end

    def added_compare
      p = github_compare_params
      return if p.values.compact.size < 2
      repo = "#{p[:old][:user]}/#{p[:old][:repo]}"
      start = p[:old][:revision]
      end_ = p[:old][:user] == p[:new][:user] ? p[:new][:revision] : "#{p[:new][:user]}:#{p[:new][:revision]}"
      puts "downloading commits #{repo} #{start} => #{end_}" if ENV['VERBOSE']
      compare_cache[[repo, start, end_]] ||= WhatIsItAbout.github.client.compare repo, start, end_
    rescue Octokit::NotFound => e
      $stderr.puts e.inspect if ENV['VERBOSE']
    end

    def removed_compare
      p = github_compare_params
      return if p.values.compact.size < 2
      repo = "#{p[:new][:user]}/#{p[:new][:repo]}"
      start = p[:new][:revision]
      end_ = p[:old][:user] == p[:new][:user] ? p[:old][:revision] : "#{p[:old][:user]}:#{p[:old][:revision]}"
      puts "downloading commits #{repo} #{start} => #{end_}" if ENV['VERBOSE']
      compare_cache[[repo, start, end_]] ||= WhatIsItAbout.github.client.compare repo, start, end_
    rescue Octokit::NotFound => e
      $stderr.puts e.inspect if ENV['VERBOSE']
    end

    def github_compare_params
      @github_compare_params ||=
        spec_map do |v, spec|
          source_uri, revision =
            case spec.source
            when Bundler::Source::Git
              [source_repositories[v], source_revisions[v]]
            when Bundler::Source::Rubygems
              uri = WhatIsItAbout.gem_repo_from_config(spec.name)
              unless uri
                uri = homepage(spec)
                uri = rubygems_source_uri(spec) unless GITHUB_RX.match(uri)
              end

              [uri, "v#{versions[v]}"]
            end

          next unless source_uri
          next unless GITHUB_RX.match(source_uri)

          match = REPO_RX.match(source_uri)

          next unless match

          {
            user: match[:user],
            repo: match[:repo],
            revision: revision
          }
        end
    end

    def homepage(spec)
      specification = fetch_spec(spec)
      return unless specification
      specification.homepage
    end

    def fetch_spec(spec)
      spec.source.fetchers.each do |fetcher|
        begin
          if ENV['VERBOSE']
            puts "fetching specification from #{fetcher.uri} for #{spec.name}-#{spec.version}"
          end
          return fetcher.fetch_spec([spec.name, spec.version, spec.platform])
        rescue Bundler::Fetcher::FallbackError => _e
          next
        rescue Bundler::HTTPError => e
          $stderr.puts e.inspect
          next
        end
      end
      nil
    end

    def rubygems_source_uri(spec)
      @rubygems_source_uri ||= {}

      return @rubygems_source_uri[spec.name] if @rubygems_source_uri.key?(spec.name)

      puts "fetching specification from rubygems api #{spec.name}" if ENV['VERBOSE']
      data = open("https://rubygems.org/api/v1/gems/#{spec.name}.json").read
      specification = JSON.load(data)
      %w(source_code_uri project_uri homepage_uri).each do |field|
        val = specification[field]
        next unless val

        next unless GITHUB_RX.match(val)
        next unless REPO_RX.match(val)
        @rubygems_source_uri[spec.name] = val
        return val
      end
      @rubygems_source_uri[spec.name] = nil
    rescue OpenURI::HTTPError => e
      @rubygems_source_uri[spec.name] = nil
      $stderr.puts e.inspect if ENV['VERBOSE']
    end
  end
end
