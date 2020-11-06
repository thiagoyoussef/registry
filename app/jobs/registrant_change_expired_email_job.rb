class RegistrantChangeExpiredEmailJob < Que::Job
  def run(domain_id:, send_to:)
    domain = Domain.find(domain_id)
    log(domain)
    RegistrantChangeMailer.expired(domain: domain,
                                   registrar: domain.registrar,
                                   registrant: domain.registrant,
                                   send_to: send_to).deliver_now
  end

  private

  def log(domain)
    message = "Send RegistrantChangeMailer#expired email for domain #{domain.name} (##{domain.id}) to #{domain.new_registrant_email}"
    logger.info(message)
  end

  def logger
    Rails.logger
  end
end
