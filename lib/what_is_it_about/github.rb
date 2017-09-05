require 'octokit'

module WhatIsItAbout
  def self.github
    @@github = Github.new
  end

  class Github
    attr_reader :client

    def initialize
      token = WhatIsItAbout.config['github']['token'] if WhatIsItAbout.config['github']
      unless token
        $stderr.puts <<-MESSAGE
Set GITHUB TOKEN https://github.com/settings/tokens in ~/.what_is_it_about

github:
  token: <YOU GITHUB TOKEN>
        MESSAGE
        exit(1)
      end
      @client = Octokit::Client.new(access_token: token)
    end
  end
end
