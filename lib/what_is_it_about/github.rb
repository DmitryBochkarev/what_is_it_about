# coding: utf-8
require 'octokit'

module WhatIsItAbout
  def self.github
    @@github = Github.new
  end

  class Github
    attr_reader :client

    def initialize
      token = WhatIsItAbout.config.get('github', 'token')
      raise 'please do $ what_is_it_abouts set_github_token TOKEN' unless token
      @client = Octokit::Client.new(access_token: token)
    end
  end
end
