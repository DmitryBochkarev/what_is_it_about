# coding: utf-8

require 'what_is_it_about'
require 'base64'
require 'thor'

module WhatIsItAbout
  class CLI < Thor
    GEMFILE_LOCK = 'Gemfile.lock'.freeze

    desc 'lock OLD_GEMFILE_LOCK NEW_GEMFILE_LOCK', ''
    def lock(old_gemfile_lock, new_gemfile_lock)
      old_content = File.open(old_gemfile_lock, 'rb', &:read)
      new_content = File.open(new_gemfile_lock, 'rb', &:read)
      report(old_content, new_content)
    end

    desc 'pull LINK', ''
    def pull(link)
      rx = %r{/(?<repo>[\w-]+/[\w-]+)/pull/(?<pull_id>[\d]+)}
      match = rx.match(link)
      raise "invalid pull request link #{link}" unless match
      pull = WhatIsItAbout.github.client.pull match[:repo], match[:pull_id]
      base_lock = WhatIsItAbout.github.client.content pull[:base][:repo][:full_name], ref: pull[:base][:sha], path: GEMFILE_LOCK
      base_content = Base64.decode64(base_lock[:content])
      head_lock = WhatIsItAbout.github.client.content pull[:head][:repo][:full_name], ref: pull[:head][:sha], path: GEMFILE_LOCK
      head_content = Base64.decode64(head_lock[:content])
      report(base_content, head_content)
    end

    desc 'diff OLD_REF NEW_REF', ''
    def diff(old_ref, new_ref)
      old_content = `git show #{old_ref}:#{GEMFILE_LOCK}`
      new_content = `git show #{new_ref}:#{GEMFILE_LOCK}`
      report(old_content, new_content)
    end

    desc 'set_github_token TOKEN', ''
    def set_github_token(token)
      WhatIsItAbout.config.set('github', 'token', token)
    end

    private

    def report(old_content, new_content)
      summary = Summary.new(old_content, new_content)
      puts Report::PlainText.new(summary)
    end
  end
end
