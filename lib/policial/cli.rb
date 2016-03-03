require 'thor'
require 'open3'

module Policial
  class CLI < Thor
    desc "investigate PULL_REQUEST", "report violations for the given PULL_REQUEST"
    long_desc <<-LONGDESC
      `policial investigate` will report violations for the given PULL_REQUEST.

      > $ policial investigate 1

      > No violations found.

      You can optionally pass the repository as first parameter if you are running `policial` outside of a repository.

      > $ policial investigate volmer/policial 1

      > No violations found.

      The status code will be 0 (no violations) or 1 (1 or more violations) depending on how many violations are found.

      The `investigate` command assumes the `GITHUB_ACCESS_TOKEN` environment variable is set. For instructions
      on how to create an access token for command-line use see: <https://help.github.com/articles/creating-an-access-token-for-command-line-use/>
    LONGDESC
    def investigate(repo = nil, pull_request_number)
      abort 'You must set the GITHUB_ACCESS_TOKEN environment variable.' unless ENV['GITHUB_ACCESS_TOKEN']

      repo ||= detect_repo_from_pwd

      octokit = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])

      begin
        pull_request = octokit.pull_request(repo, pull_request_number)
      rescue Octokit::NotFound => e
        abort "Could not find pull request ##{pull_request_number} for repository #{repo}."
      rescue Octokit::Error => e
        abort e.message
      end

      detective = Policial::Detective.new(octokit)
      detective.brief({
        repo: pull_request['head']['repo']['full_name'],
        number: pull_request['number'],
        head_sha: pull_request['head']['sha'],
        user: pull_request['user']['login'],
      })

      detective.investigate

      if detective.violations.empty?
        puts "No violations found."
        exit 0
      end

      detective.violations.each do |violation|
        puts "#{violation.filename}:#{violation.line_number} - #{violation.message}\n"
      end

      exit 1
    end

    private
    def detect_repo_from_pwd
      _, stdout, stderr = Open3.popen3('/usr/bin/env git remote -v')

      if (stderr_lines = stderr.readlines) != []
        abort stderr_lines.join("\n")
      end

      remotes = stdout.readlines.join("").match("github.com:([^\s]+)\.git")
      abort "Could not detect GitHub repository for #{ENV['PWD']}" unless remotes

      remotes[1]
    end
  end
end
