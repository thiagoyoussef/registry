require 'test_helper'
require 'application_system_test_case'

class AdminAreaCertificatesIntegrationTest < JavaScriptApplicationSystemTestCase

    # admin_api_user_certificates
    # /admin/api_users/:api_user_id/
    # /admin/api_users/:api_user_id/certificates

    setup do
        WebMock.allow_net_connect!
        sign_in users(:admin)

        @apiuser = users(:api_bestnames)
        @certificate = certificates(:api)
        @certificate.update!(csr: "-----BEGIN CERTIFICATE REQUEST-----\nMIICszCCAZsCAQAwbjELMAkGA1UEBhMCRUUxFDASBgNVBAMMC2ZyZXNoYm94LmVl\nMRAwDgYDVQQHDAdUYWxsaW5uMREwDwYDVQQKDAhGcmVzaGJveDERMA8GA1UECAwI\nSGFyanVtYWExETAPBgNVBAsMCEZyZXNoYm94MIIBIjANBgkqhkiG9w0BAQEFAAOC\nAQ8AMIIBCgKCAQEA1VVESynZoZhIbe8s9zHkELZ/ZDCGiM2Q8IIGb1IOieT5U2mx\nIsVXz85USYsSQY9+4YdEXnupq9fShArT8pstS/VN6BnxdfAiYXc3UWWAuaYAdNGJ\nDr5Jf6uMt1wVnCgoDL7eJq9tWMwARC/viT81o92fgqHFHW0wEolfCmnpik9o0ACD\nFiWZ9IBIevmFqXtq25v9CY2cT9+eZW127WtJmOY/PKJhzh0QaEYHqXTHWOLZWpnp\nHH4elyJ2CrFulOZbHPkPNB9Nf4XQjzk1ffoH6e5IVys2VV5xwcTkF0jY5XTROVxX\nlR2FWqic8Q2pIhSks48+J6o1GtXGnTxv94lSDwIDAQABoAAwDQYJKoZIhvcNAQEL\nBQADggEBAEFcYmQvcAC8773eRTWBJJNoA4kRgoXDMYiiEHih5iJPVSxfidRwYDTF\nsP+ttNTUg3JocFHY75kuM9T2USh+gu/trRF0o4WWa+AbK3JbbdjdT1xOMn7XtfUU\nZ/f1XCS9YdHQFCA6nk4Z+TLWwYsgk7n490AQOiB213fa1UIe83qIfw/3GRqRUZ7U\nwIWEGsHED5WT69GyxjyKHcqGoV7uFnqFN0sQVKVTy/NFRVQvtBUspCbsOirdDRie\nAB2KbGHL+t1QrRF10szwCJDyk5aYlVhxvdI8zn010nrxHkiyQpDFFldDMLJl10BW\n2w9PGO061z+tntdRcKQGuEpnIr9U5Vs=\n-----END CERTIFICATE REQUEST-----\n")
    end

    # Helpers =======================
    def show_certificate_info
        visit admin_api_user_certificate_path(api_user_id: @apiuser.id, id: @certificate.id)
        assert_text 'Certificates'
    end

    # TESTs ===========================
    def test_show_certificate_info
        show_certificate_info
    end

    def test_destroy_certificate
        show_certificate_info
        find(:xpath, "//a[text()='Delete']").click

        page.driver.browser.switch_to.alert.accept

        assert_text 'Record deleted'        
    end

    # download_csr_admin_api_user_certificate GET  /admin/api_users/:api_user_id/certificates/:id/download_csr(.:format)
    def test_download_csr
        get download_csr_admin_api_user_certificate_path(api_user_id: @apiuser.id, id: @certificate.id)
    
        assert_response :ok
        assert_equal 'application/octet-stream', response.headers['Content-Type']
        assert_equal "attachment; filename=\"test_bestnames.csr.pem\"; filename*=UTF-8''test_bestnames.csr.pem", response.headers['Content-Disposition']
        assert_not_empty response.body
    end

    # TODO
    # ActiveRecord::Deadlocked: PG::TRDeadlockDetected: ERROR:  deadlock detected
    # download_crt_admin_api_user_certificate GET  /admin/api_users/:api_user_id/certificates/:id/download_crt(.:format)

    # def test_download_crt
    #     get download_crt_admin_api_user_certificate_path(api_user_id: @apiuser.id, id: @certificate.id)
    
    #     assert_response :ok
    #     assert_equal 'application/octet-stream', response.headers['Content-Type']
    #     assert_equal "attachment; filename=\"test_bestnames.crt.pem\"; filename*=UTF-8''test_bestnames.crt.pem", response.headers['Content-Disposition']
    #     assert_not_empty response.body
    # end

    def test_failed_to_revoke_certificate
        show_certificate_info

        find(:xpath, "//a[text()='Revoke this certificate']").click
        assert_text 'Failed to update record'

        # element = find(:xpath, "//body").native.attribute('outerHTML')
        # puts element

        # find(:xpath, "/html/body/div[2]/div[5]/div/div/div[1]/div[2]/a[2]").click

        # assert_text 'Record deleted'
    end

end