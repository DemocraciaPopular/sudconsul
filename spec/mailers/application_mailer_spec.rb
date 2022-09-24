require "rails_helper"

describe ApplicationMailer do
  describe "#default_url_options" do
    it "returns the same options on the default tenant" do
      allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "consul.dev" })

      expect(ApplicationMailer.new.default_url_options).to eq({ host: "consul.dev" })
    end

    it "returns the host with a subdomain on other tenants" do
      allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "consul.dev" })
      create(:tenant, subdomain: "my")

      Tenant.switch("my") do
        expect(ApplicationMailer.new.default_url_options).to eq({ host: "my.consul.dev" })
      end
    end

    it "uses lvh.me for subdomains when the host is localhost" do
      allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "localhost", port: 3000 })
      create(:tenant, subdomain: "dev")

      Tenant.switch("dev") do
        expect(ApplicationMailer.new.default_url_options).to eq({ host: "dev.lvh.me", port: 3000 })
      end
    end
  end

  describe "#set_asset_host" do
    let(:mailer) { ApplicationMailer.new }
    let!(:default_asset_host) { ActionMailer::Base.asset_host }
    after { ActionMailer::Base.asset_host = default_asset_host }

    it "returns the same host on the default tenant" do
      ActionMailer::Base.asset_host = "http://consul.dev"

      mailer.set_asset_host

      expect(mailer.asset_host).to eq "http://consul.dev"
    end

    it "returns the host with a subdomain on other tenants" do
      ActionMailer::Base.asset_host = "https://consul.dev"
      create(:tenant, subdomain: "my")

      Tenant.switch("my") do
        mailer.set_asset_host

        expect(mailer.asset_host).to eq "https://my.consul.dev"
      end
    end

    it "uses lvh.me for subdomains when the host is localhost" do
      ActionMailer::Base.asset_host = "http://localhost:3000"
      create(:tenant, subdomain: "dev")

      Tenant.switch("dev") do
        mailer.set_asset_host

        expect(mailer.asset_host).to eq "http://dev.lvh.me:3000"
      end
    end
  end
end
