require "rails_helper"

describe Domain do
  it { should belong_to(:registrar) }
  it { should belong_to(:ns_set) }
  it { should belong_to(:admin_contact) }
  it { should belong_to(:owner_contact) }
  it { should belong_to(:technical_contact) }

  it 'creates a resource' do
    d = Fabricate(:domain)
    expect(d.name).to_not be_nil

    invalid = ['a.ee', "#{'a' * 64}.ee", 'ab.eu', 'test.ab.ee', '-test.ee', '-test-.ee', 'test-.ee', 'te--st.ee', 'õ.pri.ee', 'test.com', 'www.ab.ee', 'test.eu', '  .ee', 'a b.ee', 'Ž .ee']

    invalid.each do |x|
      expect(Fabricate.build(:domain, name: x).valid?).to be false
    end

    valid = ['ab.ee', "#{'a' * 63}.ee", 'te-s-t.ee', 'jäääär.ee', 'päike.pri.ee', 'õigus.edu.ee', 'õäöü.aip.ee', 'test.org.ee', 'test.med.ee', 'test.riik.ee', 'žä.ee', '  ŽŠ.ee  ']

    valid.each do |x|
      expect(Fabricate.build(:domain, name: x).valid?).to be true
    end
  end
end
