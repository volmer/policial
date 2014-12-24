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

  # rubocop:disable Metrics/ParameterLists
  def stub_comment_request(comment, repo:, pull_request:, commit:, file:, line:)
    body = JSON.generate(
      body: comment,
      commit_id: commit,
      path: file,
      position: line
    )

    stub_request(
      :post,
      url(repo, "/pulls/#{pull_request}/comments")
    ).with(body: body, headers: request_headers).to_return(status: 200)
  end
  # rubocop:enable Metrics/ParameterLists

  def stub_pull_request_comments_request(repo, pull_request)
    comments_body =
      File.read('spec/support/fixtures/pull_request_comments.json')

    path = "/pulls/#{pull_request}/comments"

    headers = { 'Content-Type' => 'application/json; charset=utf-8' }

    stub_request(:get, url(repo, path, page: 1))
      .with(headers: request_headers)
      .to_return(status: 200, body: comments_body, headers: headers)

    stub_request(:get, url(repo, path, page: 2))
      .to_return(status: 200, body: '[]', headers: headers)
  end

  private

  def request_headers
    {
      'Accept'          => 'application/vnd.github.v3+json',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Type'    => 'application/json',
      'User-Agent'      => 'Octokit Ruby Gem 3.7.0'
    }
  end

  def url(repo, path, query = {})
    URI::HTTPS.build(
      host: 'api.github.com',
      path: "/repos/#{repo}" + path,
      query: query.to_query.presence
    )
  end

  def stub_contents_request(repo, sha, file, body)
    stub_request(
      :get, url(repo, "/contents/#{file}", ref: sha)
    ).with(headers: request_headers).to_return(
      status: 200,
      body: body,
      headers: { 'Content-Type' => 'application/json; charset=utf-8' }
    )
  end
end
