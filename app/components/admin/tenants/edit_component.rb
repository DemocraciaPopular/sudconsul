class Admin::Tenants::EditComponent < ApplicationComponent
  include Header
  attr_reader :tenant

  def initialize(tenant)
    @tenant = tenant
  end

  def title
    t("admin.tenants.edit.title")
  end
end
