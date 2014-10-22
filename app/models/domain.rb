class Domain < ActiveRecord::Base
  # TODO: whois requests ip whitelist for full info for own domains and partial info for other domains
  # TODO: most inputs should be trimmed before validatation, probably some global logic?
  paginates_per 10 # just for showoff

  belongs_to :registrar
  belongs_to :owner_contact, class_name: 'Contact'

  has_many :domain_contacts, dependent: :delete_all
  accepts_nested_attributes_for :domain_contacts, allow_destroy: true

  has_many :tech_contacts,
           -> { where(domain_contacts: { contact_type: DomainContact::TECH }) },
           through: :domain_contacts, source: :contact

  has_many :admin_contacts,
           -> { where(domain_contacts: { contact_type: DomainContact::ADMIN }) },
           through: :domain_contacts, source: :contact

  has_many :nameservers, dependent: :delete_all, after_add: :track_nameserver_add

  accepts_nested_attributes_for :nameservers, allow_destroy: true,
                                              reject_if: proc { |attrs| attrs[:hostname].blank? }

  has_many :domain_statuses, dependent: :delete_all
  accepts_nested_attributes_for :domain_statuses, allow_destroy: true,
                                                  reject_if: proc { |attrs| attrs[:value].blank? }

  has_many :domain_transfers, dependent: :delete_all

  has_many :dnskeys, dependent: :delete_all
  accepts_nested_attributes_for :dnskeys, allow_destroy: true,
                                          reject_if: proc { |attrs| attrs[:public_key].blank? }

  delegate :code, to: :owner_contact, prefix: true
  delegate :email, to: :owner_contact, prefix: true
  delegate :ident, to: :owner_contact, prefix: true
  delegate :phone, to: :owner_contact, prefix: true
  delegate :name, to: :registrar, prefix: true

  before_create :generate_auth_info
  before_create :set_validity_dates
  after_create :attach_default_contacts
  after_save :manage_automatic_statuses

  validates :name_dirty, domain_name: true, uniqueness: true
  validates :period, numericality: { only_integer: true }
  validates :owner_contact, :registrar, presence: true

  validate :validate_period
  validate :validate_nameservers_count
  validate :validate_admin_contacts_count
  validate :validate_dnskeys_count
  validate :validate_nameservers_uniqueness
  validate :validate_tech_contacts_uniqueness
  validate :validate_admin_contacts_uniqueness
  validate :validate_domain_statuses_uniqueness
  validate :validate_dnskeys_uniqueness
  validate :validate_nameserver_ips

  attr_accessor :owner_contact_typeahead, :update_me

  # archiving
  # if proc works only on changes on domain sadly
  has_paper_trail class_name: 'DomainVersion', meta: { snapshot: :create_snapshot }, if: proc(&:new_version)

  def new_version
    return false if versions.try(:last).try(:snapshot) == create_snapshot
    true
  end

  def create_version
    return true unless PaperTrail.enabled?
    return true unless valid?
    touch_with_version if new_version
  end

  def track_nameserver_add(_nameserver)
    return true if versions.count == 0
    return true unless valid? && new_version

    touch_with_version
  end

  def create_snapshot
    oc = owner_contact.snapshot if owner_contact.is_a?(Contact)
    {
      owner_contact: oc,
      tech_contacts: tech_contacts.map(&:snapshot),
      admin_contacts: admin_contacts.map(&:snapshot),
      nameservers: nameservers.map(&:snapshot),
      domain: make_snapshot
    }.to_yaml
  end

  def make_snapshot
    {
      name: name,
      status: status
    }
  end

  def name=(value)
    value.strip!
    value.downcase!
    self[:name] = SimpleIDN.to_unicode(value)
    self[:name_puny] = SimpleIDN.to_ascii(value)
    self[:name_dirty] = value
  end

  def owner_contact_typeahead
    @owner_contact_typeahead || owner_contact.try(:name) || nil
  end

  def pending_transfer
    domain_transfers.find_by(status: DomainTransfer::PENDING)
  end

  def can_be_deleted?
    (domain_statuses.pluck(:value) & %W(
      #{DomainStatus::SERVER_DELETE_PROHIBITED}
    )).empty?
  end

  ### VALIDATIONS ###
  def validate_nameservers_count
    min, max = Setting.ns_min_count, Setting.ns_max_count
    return if nameservers.reject(&:marked_for_destruction?).length.between?(min, max)
    errors.add(:nameservers, :out_of_range, { min: min, max: max })
  end

  def validate_admin_contacts_count
    errors.add(:admin_contacts, :out_of_range) if admin_contacts_count.zero?
  end

  def validate_dnskeys_count
    min, max = Setting.dnskeys_min_count, Setting.dnskeys_max_count
    return if dnskeys.reject(&:marked_for_destruction?).length.between?(min, max)
    errors.add(:dnskeys, :out_of_range, { min: min, max: max })
  end

  def validate_nameservers_uniqueness
    validated = []
    list = nameservers.reject(&:marked_for_destruction?)
    list.each do |ns|
      next if ns.hostname.blank?
      existing = list.select { |x| x.hostname == ns.hostname }
      next unless existing.length > 1
      validated << ns.hostname
      errors.add(:nameservers, :invalid) if errors[:nameservers].blank?
      ns.errors.add(:hostname, :taken)
    end
  end

  def validate_nameserver_ips
    nameservers.each do |ns|
      next unless ns.hostname.end_with?(name)
      next if ns.ipv4.present?
      errors.add(:nameservers, :invalid) if errors[:nameservers].blank?
      ns.errors.add(:ipv4, :blank)
    end
  end

  def validate_tech_contacts_uniqueness
    contacts = domain_contacts.reject(&:marked_for_destruction?).select { |x| x.contact_type == DomainContact::TECH }
    validate_domain_contacts_uniqueness(contacts)
  end

  def validate_admin_contacts_uniqueness
    contacts = domain_contacts.reject(&:marked_for_destruction?).select { |x| x.contact_type == DomainContact::ADMIN }
    validate_domain_contacts_uniqueness(contacts)
  end

  def validate_domain_contacts_uniqueness(contacts)
    validated = []
    contacts.each do |dc|
      existing = contacts.select { |x| x.contact_id == dc.contact_id }
      next unless existing.length > 1
      validated << dc
      errors.add(:domain_contacts, :invalid) if errors[:domain_contacts].blank?
      dc.errors.add(:contact, :taken)
    end
  end

  def validate_domain_statuses_uniqueness
    validated = []
    list = domain_statuses.reject(&:marked_for_destruction?)
    list.each do |status|
      next if status.value.blank?
      existing = list.select { |x| x.value == status.value }
      next unless existing.length > 1
      validated << status.value
      errors.add(:domain_statuses, :invalid) if errors[:domain_statuses].blank?
      status.errors.add(:value, :taken)
    end
  end

  def validate_dnskeys_uniqueness
    validated = []
    list = dnskeys.reject(&:marked_for_destruction?)
    list.each do |dnskey|
      next if dnskey.public_key.blank?
      existing = list.select { |x| x.public_key == dnskey.public_key }
      next unless existing.length > 1
      validated << dnskey.public_key
      errors.add(:dnskeys, :invalid) if errors[:dnskeys].blank?
      dnskey.errors.add(:public_key, :taken)
    end
  end

  def validate_period
    return unless period.present?
    if period_unit == 'd'
      valid_values = %w(365 366 710 712 1065 1068)
    elsif period_unit == 'm'
      valid_values = %w(12 24 36)
    else
      valid_values = %w(1 2 3)
    end

    errors.add(:period, :out_of_range) unless valid_values.include?(period.to_s)
  end

  def all_dependencies_valid?
    validate_nameservers_count
    validate_dnskeys_count
    validate_admin_contacts_count

    errors.empty?
  end

  # used for highlighting form tabs
  def parent_valid?
    assoc_errors = errors.keys.select { |x| x.match(/\./) }
    (errors.keys - assoc_errors).empty?
  end

  def general_tab_valid?
    status_errors = errors.keys.select { |x| x.match(/domain_statuses/) }
    (errors.keys - status_errors).empty?
  end

  def statuses_tab_valid?
    !errors.keys.any? { |x| x.match(/domain_statuses/) }
  end

  ## SHARED

  def name_in_wire_format
    res = ''
    parts = name.split('.')
    parts.each do |x|
      res += sprintf('%02X', x.length)
      res += x.each_byte.map { |b| sprintf('%02X', b) }.join
    end

    res += '00'

    res
  end

  def to_s
    name
  end

  # rubocop:disable Lint/Loop
  def generate_auth_info
    begin
      self.auth_info = SecureRandom.hex
    end while self.class.exists?(auth_info: auth_info)
  end
  # rubocop:enable Lint/Loop

  def attach_default_contacts
    tech_contacts << owner_contact if tech_contacts_count.zero?
    admin_contacts << owner_contact if admin_contacts_count.zero? && owner_contact.citizen?
  end

  def set_validity_dates
    self.registered_at = Time.zone.now
    self.valid_from = Date.today
    self.valid_to = valid_from + self.class.convert_period_to_time(period, period_unit)
  end

  def tech_contacts_count
    domain_contacts.reject(&:marked_for_destruction?).select { |x| x.contact_type == DomainContact::TECH }.count
  end

  def admin_contacts_count
    domain_contacts.reject(&:marked_for_destruction?).select { |x| x.contact_type == DomainContact::ADMIN }.count
  end

  def manage_automatic_statuses
    if domain_statuses.empty? && valid?
      domain_statuses.create(value: DomainStatus::OK)
    else
      domain_statuses.find_by(value: DomainStatus::OK).try(:destroy)
    end
  end

  class << self
    def convert_period_to_time(period, unit)
      return period.to_i.days if unit == 'd'
      return period.to_i.months if unit == 'm'
      return period.to_i.years if unit == 'y'
    end
  end
end
