class Tenant < ActiveRecord::Base
  validates :subdomain,
    presence: true,
    uniqueness: true,
    exclusion: { in: ->(*) { excluded_subdomains }},
    format: { with: URI::DEFAULT_PARSER.regexp[:HOST] }
  validates :name, presence: true

  after_create :create_schema
  after_update :rename_schema
  after_destroy :destroy_schema

  def self.name_for(host)
    local_hosts = %w[localhost lvh.me example.com www.example.com]
    return nil if host.blank? || host.match?(Resolv::AddressRegex) || local_hosts.include?(host)

    domain = if host.ends_with?(".lvh.me")
               "lvh.me"
             else
               default_host
             end

    host.sub(/\Awww\./, "").sub(/#{domain}\Z/, "").sub(/\.\Z/, "").presence
  end

  def self.excluded_subdomains
    %w[mail public shared_extensions www]
  end

  def self.switch(...)
    Apartment::Tenant.switch(...)
  end

  def self.current_subdomain
    Apartment::Tenant.current
  end

  def self.default?
    current_subdomain == "public"
  end

  def self.current_secrets
    if default?
      Rails.application.secrets
    else
      @secrets ||= {}
      @secrets[current_subdomain] ||= Rails.application.secrets.merge(
        Rails.application.secrets.dig(:tenants, current_subdomain.to_sym).to_h
      )
    end
  end

  def self.run_on_each(&block)
    ["public"].union(Apartment.tenant_names).each do |subdomain|
      switch(subdomain, &block)
    end
  end

  def self.default_host
    ActionMailer::Base.default_url_options[:host]
  end

  def self.current_url_options
    ApplicationMailer.new.default_url_options
  end

  def domain
    if self.class.default_host == "localhost"
      "#{subdomain}.lvh.me"
    else
      "#{subdomain}.#{self.class.default_host}"
    end
  end

  private

    def create_schema
      Apartment::Tenant.create(subdomain)
    end

    def rename_schema
      if saved_change_to_subdomain?
        ActiveRecord::Base.connection.execute(
          "ALTER SCHEMA \"#{subdomain_before_last_save}\" RENAME TO \"#{subdomain}\";"
        )
      end
    end

    def destroy_schema
      Apartment::Tenant.drop(subdomain)
    end
end
