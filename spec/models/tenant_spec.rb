require "rails_helper"

describe Tenant do
  describe "validations" do
    let(:tenant) { build(:tenant) }

    it "is valid" do
      expect(tenant).to be_valid
    end

    it "is not valid without a subdomain" do
      tenant.subdomain = nil
      expect(tenant).not_to be_valid
    end

    it "is not valid with an already existing subdomain" do
      expect(create(:tenant, subdomain: "subdomainx")).to be_valid
      expect(build(:tenant, subdomain: "subdomainx")).not_to be_valid
    end

    it "is not valid without a name" do
      tenant.name = ""
      expect(tenant).not_to be_valid
    end
  end

  describe "#create_schema" do
    it "creates a schema creating a record" do
      create(:tenant, subdomain: "new")

      expect { Apartment::Tenant.switch("new") { nil } }.not_to raise_exception
    end

    it "does not create a schema when using the 'public' subdomain" do
      expect { create(:tenant, subdomain: "public") }.not_to raise_exception
    end
  end

  describe "#rename_schema" do
    it "renames the schema when updating the subdomain" do
      tenant = create(:tenant, subdomain: "typo")

      tenant.update!(subdomain: "notypo")

      expect { Apartment::Tenant.switch("typo") { nil } }.to raise_exception(Apartment::TenantNotFound)
      expect { Apartment::Tenant.switch("notypo") { nil } }.not_to raise_exception
    end
  end

  describe "#destroy_schema" do
    it "drops the schema when destroying a record" do
      tenant = create(:tenant, subdomain: "wrong")

      tenant.destroy!

      expect { Apartment::Tenant.switch("wrong") { nil } }.to raise_exception(Apartment::TenantNotFound)
    end
  end
end
