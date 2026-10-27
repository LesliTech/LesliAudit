# frozen_string_literal: true

account = Lesli::Account.first!
audit_account = account.audit || LesliAudit::Account.create!(
    account:,
    name: account.name
)

password = if defined?(Devise::Encryptor)
    Devise::Encryptor.digest(Lesli::User, "password123")
else
    ""
end

now = Time.current

totals = {
    users: 100,
    inactive: 12,
    locked: 5,
    unconfirmed: 8,
    never_signed_in: 14,
    active_last_30_days: 52,
    new_last_30_days: 10,
    failed_attempts: 6,
    deleted: 3
}.freeze

users = []

totals.fetch(:users).times do |index|
    uid = "DEV-USR-#{index.to_s.rjust(5, "0")}"

    users << {
        uid: uid,
        account_id: account.id,

        active: true,

        first_name: "Demo",
        last_name: "User #{index + 1}",
        email: "demo.user.#{index + 1}@lesli.dev",
        encrypted_password: password,

        confirmed_at: now - rand(1..180).days,
        confirmation_sent_at: nil,
        confirmation_token: nil,

        sign_in_count: rand(1..80),
        current_sign_in_at: now - rand(1..90).days,
        last_sign_in_at: now - rand(1..90).days,
        current_sign_in_ip: "127.0.0.1",
        last_sign_in_ip: "127.0.0.1",

        failed_attempts: 0,

        locked_at: nil,
        locked_until: nil,
        unlock_token: nil,

        created_at: now - (index % 330).days,
        updated_at: now,
        deleted_at: nil
    }
end

# Inactive users
users.first(totals.fetch(:inactive)).each do |user|
    user[:active] = false
end

# Locked users
users.slice(12, totals.fetch(:locked)).each do |user|
    user[:locked_at] = now - rand(1..15).days
    user[:locked_until] = now + rand(1..15).days
end

# Unconfirmed users
users.slice(20, totals.fetch(:unconfirmed)).each do |user|
    user[:confirmed_at] = nil
    user[:confirmation_sent_at] = now - rand(1..10).days
    user[:confirmation_token] = SecureRandom.hex(16)
end

# Never signed in
users.slice(30, totals.fetch(:never_signed_in)).each do |user|
    user[:sign_in_count] = 0
    user[:current_sign_in_at] = nil
    user[:last_sign_in_at] = nil
    user[:current_sign_in_ip] = nil
    user[:last_sign_in_ip] = nil
end

# Active in the last 30 days
users.slice(45, totals.fetch(:active_last_30_days)).each do |user|
    user[:sign_in_count] = rand(1..100)
    user[:last_sign_in_at] = now - rand(0..29).days
    user[:current_sign_in_at] = user[:last_sign_in_at]
end

# New users in the last 30 days
users.last(totals.fetch(:new_last_30_days)).each do |user|
    user[:created_at] = now - rand(0..29).days
    user[:updated_at] = now
end

# Users with failed attempts
users.slice(70, totals.fetch(:failed_attempts)).each do |user|
    user[:failed_attempts] = rand(1..5)
end

# Soft-deleted users
users.last(totals.fetch(:deleted)).each do |user|
    user[:deleted_at] = now - rand(1..30).days
end

# Remove only records owned by this seed so running it again is safe.
audit_account.user_journals.where("event_uid LIKE ?", "DEV-USR-ACTIVITY-%").delete_all
Lesli::User.unscoped.where("uid LIKE ?", "DEV-USR-%").delete_all!

# `unscoped` is required so acts_as_paranoid does not replace the explicit
# `deleted_at` values used to demonstrate deleted-user totals.
Lesli::User.unscoped.insert_all!(users)

# Retained journals provide realistic first/last activity for the Users report.
# They do not create request aggregates; the Requests report has its own seed.
demo_users = Lesli::User.where("uid LIKE ?", "DEV-USR-%").order(:id).limit(20)
journals = demo_users.flat_map do |user|
    (13.days.ago.to_date..Date.current).flat_map do |date|
        first_activity = date.in_time_zone + 8.hours + (user.id % 45).minutes
        last_activity = first_activity + 8.hours + (user.id % 90).minutes
        event_prefix = "DEV-USR-ACTIVITY-#{user.uid}-#{date.iso8601}"

        [ {
            account_id: audit_account.id,
            user_id: user.id,
            event_uid: "#{event_prefix}-FIRST",
            request_controller: "lesli_audit/users",
            request_action: "index",
            date:,
            retain: true,
            created_at: first_activity,
            updated_at: first_activity
        }, {
            account_id: audit_account.id,
            user_id: user.id,
            event_uid: "#{event_prefix}-LAST",
            request_controller: "lesli_audit/users",
            request_action: "index",
            date:,
            retain: true,
            created_at: last_activity,
            updated_at: last_activity
        } ]
    end
end

LesliAudit::UserJournal.insert_all!(journals)
