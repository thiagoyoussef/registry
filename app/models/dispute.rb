# frozen_string_literal: true

class Dispute < ApplicationRecord
  validates :domain_name, :password, :starts_at, :expires_at, presence: true
  before_validation :fill_empty_passwords
  before_validation :set_expiry_date
  validate :validate_domain_name_format
  validate :validate_domain_name_period_uniqueness

  with_options on: :admin do
    validate :validate_start_date
  end
  before_save :set_expiry_date
  before_save :sync_reserved_password
  before_save :generate_data
  after_destroy :remove_data

  scope :expired, -> { where('expires_at < ?', Time.zone.today) }
  scope :active, -> { where('expires_at > ? AND closed = false', Time.zone.today) }
  scope :closed, -> { where(closed: true) }

  alias_attribute :name, :domain_name

  def self.close_by_domain(domain_name)
    dispute = Dispute.active.find_by(domain_name: domain_name)
    dispute.update(closed: true) if dispute.present?
  end

  def set_expiry_date
    return if starts_at.blank?

    self.expires_at = starts_at + Setting.dispute_period_in_months.months
  end

  def generate_password
    self.password = SecureRandom.hex
  end

  def generate_data
    wr = Whois::Record.find_or_initialize_by(name: domain_name)
    if Domain.where(name: domain_name).any?
      @json = wr.json.with_indifferent_access
      @json[:status] << 'disputed' unless @json[:status].include? 'disputed'
      wr.json = @json
    else
      wr.json = @json = generate_json(wr) # we need @json to bind to class
    end
    wr.save!
  end

  alias_method :update_whois_record, :generate_data

  def close
    self.closed = true
    save!
  end

  def generate_json(record)
    h = HashWithIndifferentAccess.new(name: domain_name, status: ['disputed'])
    return h if record.json.empty?

    status_arr = (record.json['status'] ||= [])
    status_arr.push('disputed') unless status_arr.include? 'disputed'

    record.json['status'] = status_arr
    record.json
  end

  def remove_data
    UpdateWhoisRecordJob.enqueue domain_name, 'disputed'
  end

  def fill_empty_passwords
    generate_password if password.blank?
  end

  def sync_reserved_password
    reserved_domain = ReservedDomain.find_by(name: domain_name)
    generate_password if password.blank?

    unless reserved_domain.nil?
      reserved_domain.password = password
      reserved_domain.save!
    end

    generate_data
  end

  private

  def validate_start_date
    return if starts_at.nil?

    errors.add(:starts_at, :past) if starts_at.past?
  end

  def validate_domain_name_format
    return unless domain_name

    zone = domain_name.split('.').last
    supported_zone = DNS::Zone.origins.include?(zone)

    errors.add(:domain_name, :unsupported_zone) unless supported_zone
  end

  def validate_domain_name_period_uniqueness
    return unless new_record?

    existing_dispute = Dispute.unscoped.where(domain_name: domain_name, closed: false)
                              .where('expires_at > ?', starts_at)
    return unless existing_dispute.any?

    errors.add(:base, 'Dispute already exists for this domain at given timeframe')
  end
end
