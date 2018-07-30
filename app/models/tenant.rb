class Tenant < ActiveRecord::Base
  validates :subdomain, presence: true, uniqueness: true
  validates :name, presence: true

  after_create :create_schema
  after_update :rename_schema
  after_destroy :destroy_schema

  private

    def create_schema
      unless subdomain == "public"
        Apartment::Tenant.create(subdomain)
      end
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
