class CreateLesliAuditActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :lesli_audit_activities do |t|
      t.timestamps
    end
  end
end
