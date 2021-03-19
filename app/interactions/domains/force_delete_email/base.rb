module Domains
  module ForceDeleteEmail
    class Base < ActiveInteraction::Base
      string :email,
             description: 'Bounced email to set ForceDelete from'

      def execute
        domain_contacts = Contact.where(email: email).map(&:domain_contacts).flatten
        registrant_ids = Registrant.where(email: email).pluck(:id)

        domains = domain_contacts.map(&:domain).flatten +
                  Domain.where(registrant_id: registrant_ids)

        domains.each do |domain|
          next if domain.force_delete_scheduled?

          domain.schedule_force_delete(type: :soft,
                                       notify_by_email: true, reason: 'invalid_email')
        end
      end
    end
  end
end
