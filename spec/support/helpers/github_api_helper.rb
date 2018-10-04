# frozen_string_literal: true

require 'webmock/rspec'

# Private: Helpers to stub GitHub calls.
module GitHubApiHelper
  def stub_pull_request_files_request(repo, pull_request)
    stub_request(
      :get,
      url(repo, "/pulls/#{pull_request}/files")
    ).with(headers: request_headers).to_return(
      status: 200,
      body: File.read('spec/support/fixtures/pull_request_files.json'),
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end

  def stub_contents_request_with_content(repo, sha:, file:, content:)
    body = JSON.generate(
      content: Base64.encode64(content)
    )

    stub_contents_request(repo, sha, file, body)
  end

  def stub_contents_request_with_fixture(repo, sha:, file:, fixture:)
    body = File.read("spec/support/fixtures/#{fixture}")

    stub_contents_request(repo, sha, file, body)
  end

  private

  def request_headers
    {
      'Accept'          => 'application/vnd.github.v3+json',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Type'    => 'application/json',
      'User-Agent'      => Octokit.user_agent
    }
  end

  def url(repo, path)
    URI::HTTPS.build(
      host: 'api.github.com',
      path: "/repos/#{repo}" + path
    )
  end

  def stub_contents_request(repo, sha, file, body)
    stub_request(
      :get, url(repo, "/contents/#{file}")
    ).with(query: { ref: sha }, headers: request_headers).to_return(
      status: 200,
      body: body,
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end
end
