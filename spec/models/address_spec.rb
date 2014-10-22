require 'rails_helper'

describe Address do
  it { should belong_to(:contact) }
  it { should belong_to(:country) }
end

describe Address, '.extract_params' do

  # TODO: please fix
  it 'returns params hash', pending: true do
    Fabricate(:country, iso: 'EE')
    ph = { postalInfo: { name: 'fred', addr: { cc: 'EE', city: 'Village', street: %w(street1 street2) } }  }
    expect(Address.extract_attributes(ph[:postalInfo])).to eq({
      address_attributes: {
        country_id: 1,
        city: 'Village',
        street: 'street1',
        street2: 'street2'
      }
    })
  end
end
