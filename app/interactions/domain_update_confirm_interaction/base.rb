module DomainUpdateConfirmInteraction
  class Base < ActiveInteraction::Base
    object :domain,
           class: Domain,
           description: 'Domain to confirm update'
    string :action
    string :initiator,
           default: nil

    validates :domain, :action, presence: true
    validates :action, inclusion: { in: [RegistrantVerification::CONFIRMED,
                                         RegistrantVerification::REJECTED] }

    def raise_errors!(domain)
      if domain.errors.any?
        message = "domain #{domain.name} failed with errors #{domain.errors.full_messages}"
        throw message
      end
    end
  end
end

