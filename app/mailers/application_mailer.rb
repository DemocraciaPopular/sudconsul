class ApplicationMailer < ActionMailer::Base
  helper :settings
  helper :application
  helper :mailer
  default from: proc { "#{Setting["mailer_from_name"]} <#{Setting["mailer_from_address"]}>" }
  layout "mailer"
  before_action :set_asset_host

  def default_url_options
    if Tenant.default?
      super
    else
      super.merge(host: host_with_subdomain_for(super[:host]))
    end
  end

  def set_asset_host
    unless Tenant.default?
      self.asset_host = URI.parse(asset_host).tap do |uri|
        uri.host = host_with_subdomain_for(uri.host)
      end.to_s
    end
  end

  private

    def host_with_subdomain_for(host)
      if host == "localhost"
        "#{Tenant.current_subdomain}.lvh.me"
      else
        "#{Tenant.current_subdomain}.#{host}"
      end
    end
end
