# frozen_string_literal: true

return unless Rails.env.development?

account = Lesli::Account.first!

password = if defined?(Devise)
    Devise::Encryptor.digest(Lesli::User, "password123")
else
    BCrypt::Password.create("password123")
end

now = Time.current

# Adjust these numbers freely while building the dashboard.
TOTAL_USERS                     = 1_000
TOTAL_INACTIVE_USERS            = 120
TOTAL_LOCKED_USERS              = 45
TOTAL_UNCONFIRMED_USERS         = 80
TOTAL_USERS_NEVER_SIGNED_IN     = 140
TOTAL_USERS_ACTIVE_LAST_30_DAYS = 520
TOTAL_NEW_USERS_LAST_30_DAYS    = 75
TOTAL_USERS_WITH_FAILED_ATTEMPTS = 60
TOTAL_DELETED_USERS             = 25

users = []

TOTAL_USERS.times do |index|
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

        created_at: now - rand(31..365).days,
        updated_at: now,
        deleted_at: nil
    }
end

# Inactive users
users.first(TOTAL_INACTIVE_USERS).each do |user|
    user[:active] = false
end

# Locked users
users.slice(120, TOTAL_LOCKED_USERS).each do |user|
    user[:locked_at] = now - rand(1..15).days
    user[:locked_until] = now + rand(1..15).days
end

# Unconfirmed users
users.slice(200, TOTAL_UNCONFIRMED_USERS).each do |user|
    user[:confirmed_at] = nil
    user[:confirmation_sent_at] = now - rand(1..10).days
    user[:confirmation_token] = SecureRandom.hex(16)
end

# Never signed in
users.slice(300, TOTAL_USERS_NEVER_SIGNED_IN).each do |user|
    user[:sign_in_count] = 0
    user[:current_sign_in_at] = nil
    user[:last_sign_in_at] = nil
    user[:current_sign_in_ip] = nil
    user[:last_sign_in_ip] = nil
end

# Active in the last 30 days
users.slice(450, TOTAL_USERS_ACTIVE_LAST_30_DAYS).each do |user|
    user[:sign_in_count] = rand(1..100)
    user[:last_sign_in_at] = now - rand(0..29).days
    user[:current_sign_in_at] = user[:last_sign_in_at]
end

# New users in the last 30 days
users.last(TOTAL_NEW_USERS_LAST_30_DAYS).each do |user|
    user[:created_at] = now - rand(0..29).days
    user[:updated_at] = now
end

# Users with failed attempts
users.slice(700, TOTAL_USERS_WITH_FAILED_ATTEMPTS).each do |user|
    user[:failed_attempts] = rand(1..5)
end

# Soft-deleted users
users.last(TOTAL_DELETED_USERS).each do |user|
    user[:deleted_at] = now - rand(1..30).days
end

# Remove previous generated users only
Lesli::User.where("uid LIKE ?", "DEV-USR-%").delete_all

Lesli::User.insert_all!(users)
