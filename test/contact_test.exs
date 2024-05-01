defmodule Resellbiz.ContactTest do
  use Resellbiz.Case

  describe "search" do
    test "returns a list of contacts", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/api/contacts/search.json", fn conn ->
        assert conn.query_params == %{
                 "auth-userid" => "12345678",
                 "api-key" => "abcdefg",
                 "customer-id" => "1234567890",
                 "no-of-records" => "25",
                 "page-no" => "0"
               }

        response(conn, 200, %{
          "recsindb" => "2",
          "recsonpage" => "25",
          "result" => [
            %{
              "contact.address1" => "Calle Altenwald 1",
              "contact.city" => "Los Angeles",
              "contact.company" => "NA",
              "contact.contactid" => "12345678",
              "contact.country" => "US",
              "contact.creationdt" => "1550546208",
              "contact.emailaddr" => "altenwald@email.com",
              "contact.name" => "Altenwald",
              "contact.state" => "CA",
              "contact.telno" => "666555444",
              "contact.telnocc" => "1",
              "contact.timestamp" => "2019-02-19 03:16:47.869646+00",
              "contact.type" => "Contact",
              "contact.zip" => "90001",
              "designated-agent" => "true",
              "entity.currentstatus" => "Active",
              "entity.customerid" => "54321",
              "entity.description" => "DomainContact",
              "entity.entityid" => "12345678",
              "whoisValidity" => %{"invalidData" => [], "valid" => "true"}
            },
            %{
              "contact.address1" => "Calle Altenwald 2",
              "contact.city" => "Los Angeles",
              "contact.company" => "NA",
              "contact.contactid" => "12345679",
              "contact.country" => "US",
              "contact.creationdt" => "1550546208",
              "contact.emailaddr" => "altenwald2@email.com",
              "contact.name" => "Altenwald 2",
              "contact.state" => "CA",
              "contact.telno" => "666444555",
              "contact.telnocc" => "1",
              "contact.timestamp" => "2019-02-19 03:16:47.869646+00",
              "contact.type" => "Contact",
              "contact.zip" => "90002",
              "designated-agent" => "true",
              "entity.currentstatus" => "Active",
              "entity.customerid" => "54321",
              "entity.description" => "DomainContact",
              "entity.entityid" => "12345679",
              "whoisValidity" => %{"invalidData" => [], "valid" => "true"}
            }
          ]
        })
      end)

      assert Resellbiz.Contact.search() == %Resellbiz.Contact.Search{
               total: 2,
               page_size: 25,
               result: [
                 %Resellbiz.Contact.Details{
                   id: 12_345_678,
                   name: "Altenwald",
                   company: "NA",
                   type: :contact,
                   email: "altenwald@email.com",
                   telno_cc: 1,
                   telno: "666555444",
                   address: "Calle Altenwald 1",
                   address_extra1: nil,
                   address_extra2: nil,
                   city: "Los Angeles",
                   state: "CA",
                   country: "US",
                   zip: "90001",
                   status: :active
                 },
                 %Resellbiz.Contact.Details{
                   id: 12_345_679,
                   name: "Altenwald 2",
                   company: "NA",
                   type: :contact,
                   email: "altenwald2@email.com",
                   telno_cc: 1,
                   telno: "666444555",
                   address: "Calle Altenwald 2",
                   address_extra1: nil,
                   address_extra2: nil,
                   city: "Los Angeles",
                   state: "CA",
                   country: "US",
                   zip: "90002",
                   status: :active
                 }
               ]
             }
    end
  end

  describe "add" do
    test "valid Contact", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/api/contacts/add.json", fn conn ->
        assert conn.query_params == %{
                 "auth-userid" => "12345678",
                 "api-key" => "abcdefg",
                 "customer-id" => "1234567890",
                 "address-line-1" => "Altenwaldstraat 1",
                 "city" => "Amsterdam",
                 "company" => "NA",
                 "country" => "NL",
                 "email" => "altenwald@email.com",
                 "name" => "Altenwald",
                 "phone" => "666555444",
                 "phone-cc" => "31",
                 "type" => "Contact",
                 "zipcode" => "1111AA"
               }

        response(conn, 200, 12_345_678)
      end)

      assert Resellbiz.Contact.add(%{
               name: "Altenwald",
               company: "NA",
               email: "altenwald@email.com",
               telno_cc: 31,
               telno: "666555444",
               address: "Altenwaldstraat 1",
               city: "Amsterdam",
               country: "NL",
               zip: "1111AA"
             }) == {:ok, 12_345_678}
    end

    test "valid EsContact", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/api/contacts/add.json", fn conn ->
        assert conn.query_params == %{
                 "auth-userid" => "12345678",
                 "api-key" => "abcdefg",
                 "customer-id" => "1234567890",
                 "address-line-1" => "Calle Altenwald 1",
                 "city" => "Cordoba",
                 "company" => "NA",
                 "country" => "ES",
                 "email" => "altenwald@email.com",
                 "name" => "Altenwald",
                 "phone" => "666555444",
                 "phone-cc" => "1",
                 "state" => "Cordoba",
                 "type" => "EsContact",
                 "zipcode" => "90001",
                 "attr-name1" => "es_form_juridica",
                 "attr-value1" => "1",
                 "attr-name2" => "es_tipo_identificacion",
                 "attr-value2" => "1",
                 "attr-name3" => "es_identificacion",
                 "attr-value3" => "12345678A"
               }

        response(conn, 200, 12_345_678)
      end)

      assert Resellbiz.Contact.add(%{
               name: "Altenwald",
               company: "NA",
               type: :es_contact,
               email: "altenwald@email.com",
               telno_cc: 1,
               telno: "666555444",
               address: "Calle Altenwald 1",
               city: "Cordoba",
               state: "Cordoba",
               country: "ES",
               zip: "90001",
               es_form_juridica: :natural_person,
               es_tipo_identificacion: :dni_nif,
               es_identificacion: "12345678A"
             }) == {:ok, 12_345_678}
    end
  end
end
