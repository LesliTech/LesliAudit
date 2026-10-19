require "test_helper"

module LesliAudit
    class UserJournalTest < ActiveSupport::TestCase
        test "retained journals require request dimensions" do
            journal = audit_account.user_journals.new(
                event_uid: "request-1",
                date: Date.current,
                retain: true
            )

            assert_not journal.valid?
            assert_includes journal.errors[:request_controller], "can't be blank"
            assert_includes journal.errors[:request_action], "can't be blank"
        end

        test "transient processed rows may be scrubbed" do
            journal = audit_account.user_journals.create!(
                event_uid: "request-2",
                date: Date.current,
                retain: false,
                processed_at: Time.current,
                analytics_enabled: true
            )

            assert_includes LesliAudit::UserJournal.processed, journal
            assert_includes LesliAudit::UserJournal.transient, journal
            assert_not_includes LesliAudit::UserJournal.pending, journal
        end
    end
end

