require 'application_system_test_case'

class AdminAreaBankStatementTest < ApplicationSystemTestCase
  setup do
    sign_in users(:admin)
    travel_to Time.zone.parse('2010-07-05 00:30:00')

    @invoice = invoices(:one)
  end

  def test_update_bank_statement
    visit admin_bank_statement_path(id: @invoice.id)

    click_link_or_button 'Add'

    fill_in 'Description', with: 'Invoice with id 123'
    fill_in 'Reference number', with: '1232'
    fill_in 'Sum', with: '500'
    fill_in 'Paid at', with: Time.zone.today.to_s

    click_link_or_button 'Save'
    assert_text 'Bank transaction'

    click_link_or_button 'Edit'
    fill_in 'Description', with: 'Invoice with id 123'
    click_link_or_button 'Save'

    assert_text 'Record updated'
  end

  def test_bind_bank
    visit admin_bank_statement_path(id: @invoice.id)
    click_link_or_button 'Bind invoices'

    assert_text 'No invoices were binded'
  end

  def test_can_create_statement_manually
    create_bank_statement
    assert_text 'Record created'
  end

  def test_can_add_transaction_to_statement_manually
    create_bank_statement
    click_link_or_button 'Add'
    assert_text 'Create bank transaction'

    fill_in 'Description', with: 'Invoice with id 123'
    fill_in 'Reference number', with: '1232'
    fill_in 'Sum', with: '500'
    fill_in 'Paid at', with: Time.zone.today.to_s
    click_link_or_button 'Save'
    assert_text 'Record created'
  end

  def test_can_bind_statement_transactions
    registrar = registrars(:bestnames)
    registrar.issue_prepayment_invoice(500)
    invoice = registrar.invoices.last

    create_bank_statement
    click_link_or_button 'Add'
    assert_text 'Create bank transaction'

    fill_in 'Description', with: "Invoice with id #{invoice.number}"
    fill_in 'Reference number', with: invoice.reference_no
    fill_in 'Sum', with: invoice.total
    fill_in 'Paid at', with: Time.zone.today.to_s
    click_link_or_button 'Save'

    click_link_or_button 'Back to bank statement'
    click_link_or_button 'Bind invoices'

    assert_text 'Invoices were fully binded'
  end

  def create_bank_statement
    visit admin_bank_statements_path
    click_link_or_button 'Add'
    click_link_or_button 'Save'
  end
end
