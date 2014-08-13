module EppContactXmlBuilder
  
  def contact_check_xml(xml_params={})

    xml_params[:ids] = xml_params[:ids] || [ { id: 'check-1234' }, { id: 'check-4321' } ]  

    xml = Builder::XmlMarkup.new

    xml.instruct!(:xml, standalone: 'no')
    xml.epp('xmlns' => 'urn:ietf:params:xml:ns:epp-1.0') do
      xml.command do
        xml.check do
          xml.tag!('contact:check', 'xmlns:contact' => 'urn:ietf:params:xml:ns:contact-1.0') do
            unless xml_params[:ids] == [false]
              xml_params[:ids].each do |x|
                xml.tag!('contact:id', x[:id])
              end
            end
          end
        end
        xml.clTRID 'ABC-12345'
      end
    end
  end

  def contact_create_xml(xml_params={})
    #xml_params[:ids] = xml_params[:ids] || [ { id: 'check-1234' }, { id: 'check-4321' } ]  
    xml = Builder::XmlMarkup.new
    
    xml_params[:addr] = xml_params[:addr] ||  { street: '123 Example Dr.', street2: 'Suite 100', street3: nil,
                                                city: 'Megaton' , sp: 'F3 ' , pc: '201-33' , cc: 'EE' }
    xml_params[:authInfo] = xml_params[:authInfo] || { pw: 'Aas34fq' } 


    xml.instruct!(:xml, standalone: 'no')
    xml.epp('xmlns' => 'urn:ietf:params:xml:ns:epp-1.0') do
      xml.command do
        xml.create do
          xml.tag!('contact:create', 'xmlns:contact' => 'urn:ietf:params:xml:ns:contact-1.0') do
            xml.tag!('contact:id', xml_params[:id], 'sh8013') unless xml_params[:id] == false
            unless xml_params[:postalInfo] == [false]
              xml.tag!('contact:postalInfo') do
                xml.tag!('contact:name', ( xml_params[:name] || 'Sillius Soddus'  ))  unless xml_params[:name] == false
                xml.tag!('contact:org', ( xml_params[:org_name] || 'Example Inc.' ))  unless xml_params[:org_name] == false
                unless xml_params[:addr] == [false]
                  xml.tag!('contact:addr') do
                    xml.tag!('contact:street', xml_params[:addr][:street]   ) unless xml_params[:addr][:street] == false
                    xml.tag!('contact:street', xml_params[:addr][:street2]  ) unless xml_params[:addr][:street2] == false
                    xml.tag!('contact:street', xml_params[:addr][:street3]  ) unless xml_params[:addr][:street3] == false
                    xml.tag!('contact:city'  , xml_params[:addr][:city]     ) unless xml_params[:addr][:city] == false
                    xml.tag!('contact:sp'    , xml_params[:addr][:sp]       ) unless xml_params[:addr][:sp] == false
                    xml.tag!('contact:pc'    , xml_params[:addr][:pc]       ) unless xml_params[:addr][:pc] == false
                    xml.tag!('contact:cc'    , xml_params[:addr][:cc]       ) unless xml_params[:addr][:cc] == false
                  end
                end
              end
            end
            xml.tag!('contact:voice', (xml_params[:voice] || '+372.1234567')) unless xml_params[:voice] == false
            xml.tag!('contact:fax', (xml_params[:fax] || '123123' )) unless xml_params[:fax] == false
            xml.tag!('contact:email', (xml_params[:email] || 'example@test.example')) unless xml_params[:email] == false
            xml.tag!('contact:ident', (xml_params[:ident] || '37605030299')) unless xml_params[:ident] == false
            unless xml_params[:authInfo] == [false]
              xml.tag!('contact:authInfo') do
                xml.tag!('contact:pw', xml_params[:authInfo][:pw] ) unless xml_params[:authInfo][:pw] == false
              end
            end
            #Disclosure logic
          end
        end
        xml.clTRID 'ABC-12345'
      end
    end
  end

end

RSpec.configure do |c|
  c.include EppContactXmlBuilder
end
