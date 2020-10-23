@isTest
public with sharing class TIP_Rest_GetPartnersTest {

    final static String RECORD_TYPE_NAME = 'TIP Partner';

    @TestSetup
    static void makeData(){
        List<Account> accounts = new List<Account>();
        Account compliantAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(RECORD_TYPE_NAME).getRecordTypeId(),
            Ambassador_Buddy__c = 'ambassador buddy text ',
            Business_type__c = 'TL',
            DFS_account_team__c = 'CMO',
            Email_of_the_DFS_Account_Manager__c = 'dfsaccmng1@mail.mail',
            Enrollment_Location__c = 'SINGAPORE HOTELS',
            Major_customer_nationality_passport__c = 'China',
            Name = 'Tip Account Dummy Name 1',
            Name_of_the_DFS_Account_Manager__c = 'account manager name ',
            Ownership = 'Other',
            Partner_end_date__c = Date.newInstance(2049,12,31),
            Partner_start_date__c = Date.newInstance(2019,10,03),
            Partner_type__c = 'Individual Partner',
            Short_name__c = 'TIM Test'
        );
        accounts.add(compliantAccount);

        Account nonCompliantAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(RECORD_TYPE_NAME).getRecordTypeId(),
            Ambassador_Buddy__c = 'ambassador buddy text ',
            Business_type__c = 'TL',
            DFS_account_team__c = 'CMO',
            Email_of_the_DFS_Account_Manager__c = 'dfsaccmng1@mail.mail',
            Enrollment_Location__c = 'SINGAPORE HOTELS',
            Major_customer_nationality_passport__c = 'China',
            Name = 'Tip Account Dummy Name 1',
            Name_of_the_DFS_Account_Manager__c = 'account manager name ',
            Ownership = 'Other',
            Partner_end_date__c = Date.newInstance(2049,12,31),
            Partner_start_date__c = Date.newInstance(2019,10,03),
            Partner_type__c = 'Individual Partner',
            Short_name__c = 'TIM Test'
        );
        accounts.add(nonCompliantAccount);
        insert accounts;

        List<TIP_Working_Destination__c> wds = new List<TIP_Working_Destination__c>();
        TIP_Working_Destination__c wdVenice1 = new TIP_Working_Destination__c(
            Account__c = compliantAccount.Id,
            CMS_code__c = '11111',
            Code__c = '17',
            Working_Destination__c = 'Venice',
            SAP_Payee_Number__c = '123123123'
        );
        wds.add(wdVenice1);

        TIP_Working_Destination__c wdVenice2 = new TIP_Working_Destination__c(
            Account__c = nonCompliantAccount.Id,
            CMS_code__c = '22222',
            Code__c = '17',
            Working_Destination__c = 'Venice',
            SAP_Payee_Number__c = '234234234'
        );
        wds.add(wdVenice2);

        TIP_Working_Destination__c wdParis1 = new TIP_Working_Destination__c(
            Account__c = nonCompliantAccount.Id,
            CMS_code__c = '11111',
            Code__c = '63',
            Working_Destination__c = 'Paris',
            SAP_Payee_Number__c = '345345345'
        );
        wds.add(wdParis1);

        TIP_Working_Destination__c wdParis2 = new TIP_Working_Destination__c(
            Account__c = nonCompliantAccount.Id,
            CMS_code__c = '22222',
            Code__c = '63',
            Working_Destination__c = 'Paris',
            SAP_Payee_Number__c = '456456456'
        );
        wds.add(wdParis2);

        insert wds;

        List<Contact> cts = new List<Contact>();
        Contact c1 = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(RECORD_TYPE_NAME).getRecordTypeId(),
            FirstName = 'FName1',
            LastName = 'LastName1',
            First_Name_Native__c = 'FName1',
            Last_Name_Native__c = 'LastName1',
            TIP_Nationality__c = 'China',
            AccountId = compliantAccount.Id,
            Email = 'testemail@test.com'
        );
        cts.add(c1);

        Contact c2 = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(RECORD_TYPE_NAME).getRecordTypeId(),
            FirstName = 'FName2',
            LastName = 'LastName2',
            First_Name_Native__c = 'FName2',
            Last_Name_Native__c = 'LastName2',
            TIP_Nationality__c = 'Japan',
            AccountId = nonCompliantAccount.Id,
            Email = 'testemail@test.com'
        );
        cts.add(c2);

        insert cts;
    }
    
    @isTest
    private static void testGetNonCompliantPartners() {
        RestRequest request = new RestRequest();
		request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/GetPartners/';
		request.httpMethod = 'GET';
		request.addParameter('partnerCompliance', 'false');
		request.addParameter('countryOfTaxResidence', '!China');
		request.addParameter('dfsAccountTeam', 'CMO');
		request.addParameter('partnerType', 'Individual Partner');
		RestContext.request = request;

        Test.startTest();
		List<TIP_Wrappers.PartnerData> resp = TIP_Rest_GetPartners.doGet();
        List<Account> acs = [SELECT  Name, (SELECT External_ID__c, CMS_code__c, Code__c, Partner_Compliance__c, SAP_Payee_Number__c, Tax_Exemption__c, Working_Destination__c, Name FROM TIP_Working_Destinations__r WHERE Partner_Compliance__c = false), (SELECT Name FROM Contacts WHERE TIP_Nationality__c NOT IN ('China')) FROM Account WHERE DFS_account_team__c IN ('CMO') AND Partner_type__c IN ('Individual Partner')];
        System.debug(acs);
        System.debug(acs[0].TIP_Working_Destinations__r);
        System.debug(acs[0].Contacts);
        Test.stopTest();

        System.assert(resp != null);
        System.assert(resp.size() > 0);
    }

}
