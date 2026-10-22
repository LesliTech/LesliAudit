module LesliAudit
    class Account < ApplicationRecord
        belongs_to :account,
            class_name: "Lesli::Account",
            inverse_of: :audit

        validates :account_id, uniqueness: true

        has_many :dashboards

        has_many :account_logs,
            inverse_of: :account,
            dependent: :delete_all

        has_many :account_devices,
            inverse_of: :account,
            dependent: :delete_all

        has_many :account_requests,
            inverse_of: :account,
            dependent: :delete_all

        has_many :user_logs,
            inverse_of: :account,
            dependent: :delete_all

        has_many :user_journals,
            inverse_of: :account,
            dependent: :delete_all

        has_many :user_requests,
            inverse_of: :account,
            dependent: :delete_all
    end
end
