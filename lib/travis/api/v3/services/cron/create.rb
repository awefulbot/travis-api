module Travis::API::V3
  class Services::Cron::Create < Service
    result_type :cron
    params :interval, :run_only_when_new_commit

    def run!
      repository = check_login_and_find(:repository)
      raise NotFound unless branch = find(:branch, repository)
      raise Error.new('Crons can only be set up for branches existing on GitHub!', status: 422) unless branch.exists_on_github
      raise Error.new('Invalid value for interval. Interval must be "daily", "weekly" or "monthly"!', status: 422) unless ["daily", "weekly", "monthly"].include?(params["interval"])
      access_control.permissions(repository).create_cron!
      access_control.permissions(branch.cron).delete! if branch.cron
      query.create(branch, params["interval"], params["run_only_when_new_commit"] ? params["run_only_when_new_commit"] : false)
    end

  end
end
