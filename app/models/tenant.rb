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

  def self.excluded_subdomains
    Apartment::Elevators::Subdomain.excluded_subdomains + %w[mail shared_extensions]
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

  def self.current_url_options
    ApplicationMailer.new.default_url_options
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
