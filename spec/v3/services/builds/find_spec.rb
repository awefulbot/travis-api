require 'spec_helper'

describe Travis::API::V3::Services::Builds::Find do
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.last }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching builds on a public repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal/builds")     }
    example    { expect(last_response).to be_ok }
  end

  describe "fetching builds on a non-existing repository by slug" do
    before     { get("/v3/repo/svenfuchs%2Fminimal1/builds")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "builds on public repository" do
    before     { get("/v3/repo/#{repo.id}/builds?limit=1") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
      "@type"              => "builds",
      "@href"              => "/v3/repo/#{repo.id}/builds?limit=1",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 3,
        "is_first"         => true,
        "is_last"          => false,
        "next"             => {
          "@href"          => "/v3/repo/#{repo.id}/builds?limit=1&offset=1",
          "offset"         => 1,
          "limit"          =>1},
        "prev"             =>nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/builds?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/builds?limit=1&offset=2",
          "offset"         => 2,
          "limit"          => 1 }},
      "builds"             => [{
        "@type"            => "build",
        "@href"            => "/v3/build/#{build.id}",
        "id"               => build.id,
        "number"           => "3",
        "state"            => "configured",
        "duration"         => nil,
        "event_type"       => "push",
        "previous_state"   => "passed",
        "started_at"       => "2010-11-12T13:00:00Z",
        "finished_at"      => nil,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/#{repo.id}",
          "id"             => repo.id,
          "slug"=>"svenfuchs/minimal" },
        "branch"           => {
          "@type"          => "branch",
          "@href"          => "/v3/repo/#{repo.id}/branch/master",
          "name"           => "master",
          "last_build"     => {
            "@href"=>"/v3/build/#{build.id}" }},
        "commit"           => {
          "@type"          => "commit",
          "id"             => 5,
          "sha"            => "add057e66c3e1d59ef1f",
          "ref"            => "refs/heads/master",
          "message"        => "unignore Gemfile.lock",
          "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"   => "2010-11-12T12:55:00Z"}}],
   }}
  end

  describe "builds private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/builds?limit=1", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"              => "builds",
      "@href"              => "/v3/repo/#{repo.id}/builds?limit=1",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 3,
        "is_first"         => true,
        "is_last"          => false,
        "next"             => {
          "@href"          => "/v3/repo/#{repo.id}/builds?limit=1&offset=1",
          "offset"         => 1,
          "limit"          => 1 },
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/builds?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/builds?limit=1&offset=2",
          "offset"         => 2,
          "limit"          => 1 }},
      "builds"             => [{
        "@type"            => "build",
        "@href"            => "/v3/build/#{build.id}",
        "id"               => build.id,
        "number"           => "3",
        "state"            => "configured",
        "duration"         => nil,
        "event_type"       => "push",
        "previous_state"   => "passed",
        "started_at"       => "2010-11-12T13:00:00Z",
        "finished_at"      =>nil,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/#{repo.id}",
          "id"             => repo.id,
          "slug"           => "svenfuchs/minimal"},
        "branch"           => {
          "@type"          => "branch",
          "@href"          => "/v3/repo/#{repo.id}/branch/master",
          "name"           => "master",
          "last_build"     => {
            "@href"        => "/v3/build/#{build.id}"}},
        "commit"           => {
          "@type"          => "commit",
          "id"             => 5,
          "sha"            => "add057e66c3e1d59ef1f",
          "ref"            => "refs/heads/master",
          "message"        => "unignore Gemfile.lock",
          "compare_url"    => "https://github.com/svenfuchs/minimal/compare/master...develop",
          "committed_at"   => "2010-11-12T12:55:00Z"}}]
    }}
  end

  describe "including branch.name params on existing branch" do
    before  { get("/v3/repo/#{repo.id}/builds?branch.name=master&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['builds'].first['branch']['name']).to be == ("master") }
  end

  describe "including branch.name params on non-existing branch" do
    before  { get("/v3/repo/#{repo.id}/builds?branch.name=missing&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body['builds']).to be == [] }
  end
end
