namespace :budgets do
  namespace :email do
    desc "Sends emails to authors of selected investments"
    task selected: :environment do
      Tenant.run_on_each { Budget.last.email_selected }
    end

    desc "Sends emails to authors of unselected investments"
    task unselected: :environment do
      Tenant.run_on_each { Budget.last.email_unselected }
    end
  end
end
