require "rails_helper"

describe Mailer do
  describe "#comment" do
    it "sends emails in the user's locale" do
      user = create(:user, locale: "es")
      proposal = create(:proposal, author: user)
      comment = create(:comment, commentable: proposal)

      email = I18n.with_locale :en do
        Mailer.comment(comment)
      end

      expect(email.subject).to include("comentado")
    end

    it "reads the from address at runtime" do
      Setting["mailer_from_name"] = "New organization"
      Setting["mailer_from_address"] = "new@consul.dev"

      email = Mailer.comment(create(:comment))

      expect(email).to deliver_from "New organization <new@consul.dev>"
    end

    it "sends emails for comments on legislation proposals" do
      email = Mailer.comment(create(:legislation_proposal_comment))

      expect(email.subject).to include("commented on your proposal")
    end
  end

  describe "#manage_subscriptions_token" do
    let(:user) { create(:user) }
    let(:proposal) { create(:proposal, author: user) }
    let(:comment) { create(:comment, commentable: proposal) }

    it "generates a subscriptions token when the receiver doesn't have one" do
      user.update!(subscriptions_token: nil)

      Mailer.comment(comment).deliver_now

      expect(user.reload.subscriptions_token).to be_present
    end

    it "uses the existing subscriptions token when the receivesr already has one" do
      user.update!(subscriptions_token: "subscriptions_token_value")

      Mailer.comment(comment).deliver_now

      expect(user.subscriptions_token).to eq "subscriptions_token_value"
    end
  end

  describe "multitenancy" do
    let!(:default_asset_host) { ActionMailer::Base.asset_host }

    before do
      allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "consul.dev" })
      ActionMailer::Base.asset_host = "http://assets.consul.dev"
    end

    after { ActionMailer::Base.asset_host = default_asset_host }

    it "uses the current tenant when using delayed jobs", :delay_jobs do
      create(:tenant, subdomain: "delay")

      Apartment::Tenant.switch("delay") do
        Setting["org_name"] = "Delayed tenant"

        Mailer.delay.user_invite("test@consul.dev")
      end

      Delayed::Worker.new.work_off
      body = ActionMailer::Base.deliveries.last.body.to_s
      expect(body).to match "Delayed tenant"
      expect(body).to match "href=\"http://delay.consul.dev/"
      expect(body).to match "src=\"http://delay.assets.consul.dev/"
    end
  end
end
