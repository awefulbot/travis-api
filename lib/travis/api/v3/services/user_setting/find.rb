module Travis::API::V3
  class Services::UserSetting::Find < Service
    def run!
      repo = check_login_and_find(:repository)
      query.find(repo)
    end
  end
end
