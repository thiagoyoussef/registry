class InactiveContacts
  attr_reader :contacts

  def initialize(contacts = Contact.archivable)
    @contacts = contacts
  end

  def archive(verified: false)
    contacts.each do |contact|
      log("Archiving contact: id(#{contact.id}), code(#{contact.code})")

      contact.archive(verified: verified)
      yield contact if block_given?
    end
  end

  def log(msg)
    @logger ||= Logger.new(STDOUT)
    @logger.info(msg)
  end
end
