require 'application_system_test_case'

class NewInvoicePaymentTest < ApplicationSystemTestCase
  def setup
    super
    eis_response = OpenStruct.new(body: "{\"payment_link\":\"http://link.test\"}")
    Spy.on_instance_method(EisBilling::AddDeposits, :send_invoice).and_return(eis_response)

    @original_vat_prc = Setting.registry_vat_prc
    Setting.registry_vat_prc = 0.2
    @user = users(:api_bestnames)
    sign_in @user
  end

  def teardown
    super

    Setting.registry_vat_prc = @original_vat_prc
  end

  def create_invoice_and_visit_its_page
    visit registrar_invoices_path
    click_link_or_button 'Add deposit'
    fill_in 'Amount', with: '200.00'
    fill_in 'Description', with: 'My first invoice'
    click_link_or_button 'Add'
  end

  def test_create_new_SEB_payment
    if Feature.billing_system_integrated?
      invoice_n = Invoice.order(number: :desc).last.number
      stub_request(:post, "http://eis_billing_system:3000/api/v1/invoice_generator/invoice_number_generator").
        to_return(status: 200, body: "{\"invoice_number\":\"#{invoice_n + 3}\"}", headers: {})

      stub_request(:put, "http://registry:3000/eis_billing/e_invoice_response").
        to_return(status: 200, body: "{\"invoice_number\":\"#{invoice_n + 3}\"}, {\"date\":\"#{Time.zone.now-10.minutes}\"}", headers: {})

      stub_request(:post, "http://eis_billing_system:3000/api/v1/e_invoice/e_invoice").
        to_return(status: 200, body: "", headers: {})

      create_invoice_and_visit_its_page
      click_link_or_button 'seb'
      form = page.find('form')
      assert_equal('https://www.seb.ee/cgi-bin/dv.sh/ipank.r', form['action'])
      assert_equal('post', form['method'])
      assert_equal('240.00', form.find_by_id('VK_AMOUNT', visible: false).value)
    end
  end

  def test_create_new_Every_Pay_payment
    if Feature.billing_system_integrated?
      invoice_n = Invoice.order(number: :desc).last.number
      stub_request(:post, "http://eis_billing_system:3000/api/v1/invoice_generator/invoice_number_generator").
        to_return(status: 200, body: "{\"invoice_number\":\"#{invoice_n + 3}\"}", headers: {})

      stub_request(:put, "http://registry:3000/eis_billing/e_invoice_response").
        to_return(status: 200, body: "{\"invoice_number\":\"#{invoice_n + 3}\"}, {\"date\":\"#{Time.zone.now-10.minutes}\"}", headers: {})

      stub_request(:post, "http://eis_billing_system:3000/api/v1/e_invoice/e_invoice").
        to_return(status: 200, body: "", headers: {})

      create_invoice_and_visit_its_page
      click_link_or_button 'every_pay'
      expected_hmac_fields = 'account_id,amount,api_username,callback_url,' +
                            'customer_url,hmac_fields,nonce,order_reference,timestamp,transaction_type'

      form = page.find('form')
      assert_equal('https://igw-demo.every-pay.com/transactions/', form['action'])
      assert_equal('post', form['method'])
      assert_equal(expected_hmac_fields, form.find_by_id('hmac_fields', visible: false).value)
      assert_equal('240.00', form.find_by_id('amount', visible: false).value)
    end
  end
end
