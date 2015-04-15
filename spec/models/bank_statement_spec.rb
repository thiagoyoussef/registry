require 'rails_helper'

describe BankStatement do
  it { should have_many(:bank_transactions) }

  context 'with invalid attribute' do
    before :all do
      @bank_statement = BankStatement.new
    end

    it 'should not be valid' do
      @bank_statement.valid?
      @bank_statement.errors.full_messages.should match_array([
        "Bank code is missing",
        "Iban is missing",
        "Queried at is missing"
      ])
    end

    # it 'should not have any versions' do
    #   @bank_statement.versions.should == []
    # end
  end

  context 'with valid attributes' do
    before :all do
      @bank_statement = Fabricate(:bank_statement)
    end

    it 'should be valid' do
      @bank_statement.valid?
      @bank_statement.errors.full_messages.should match_array([])
    end

    it 'should be valid twice' do
      @bank_statement = Fabricate(:bank_statement)
      @bank_statement.valid?
      @bank_statement.errors.full_messages.should match_array([])
    end

    it 'should bind transactions with invoices' do
      Fabricate(:eis)
      r = Fabricate(:registrar, reference_no: 'RF7086666663')
      r.issue_prepayment_invoice(200, 'add some money')

      bs = Fabricate(:bank_statement, bank_transactions: [
        Fabricate(:bank_transaction, {
          sum: 240.0, # with vat
          reference_no: 'RF7086666663',
          description: 'Invoice no. 1'
        }),
        Fabricate(:bank_transaction, {
          sum: 120.0,
          reference_no: 'RF7086666663',
          description: 'Invoice no. 1'
        })
      ])

      bs.bank_transactions.count.should == 2

      AccountActivity.count.should == 0
      bs.bind_invoices

      AccountActivity.count.should == 1

      r.cash_account.balance.should == 240.0

      bs.bank_transactions.unbinded.count.should == 1
    end

    # it 'should have one version' do
    #   with_versioning do
    #     @bank_statement.versions.should == []
    #     @bank_statement.body = 'New body'
    #     @bank_statement.save
    #     @bank_statement.errors.full_messages.should match_array([])
    #     @bank_statement.versions.size.should == 1
    #   end
    # end
  end
end
