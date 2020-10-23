@isTest
public with sharing class TIP_REST_CreatePartnerTest {

    final static String RECORD_TYPE_NAME = 'TIP Partner';

    @TestSetup
    private static void makeData(){
        TIP_CMS_Codes__c cmsSetting = new TIP_CMS_Codes__c(
            CMS_Code_Range_MIN__c = '30000',
            CMS_Code_Range_MAX__c = '39999',
            Is_Active__c = true,
            Last_Generated__c = '29999'
        );
        insert cmsSetting;
    }

    private static List<TIP_Wrappers.PartnerData> genericJSON() {

        List<TIP_Wrappers.PartnerData> requestData = new List<TIP_Wrappers.PartnerData>();

        TIP_Wrappers.PartnerData partner = new TIP_Wrappers.PartnerData();
        partner.externalId = 'Test1';
        partner.name = 'Test Acc1';
        partner.ownerId = UserInfo.getUserName();
        partner.shortName = 'Test Acc1';
        partner.majorCustomerNationality = 'CN';
        partner.countryCodeMobile = '212';
        partner.phone = '123123123';
        partner.businessType = 'OTA';
        partner.partnerType = 'Corporate Partner';
        partner.partnerStartDate = '2019-10-03';
        partner.partnerEndDate = '2049-12-31';
        partner.dfsAccountTeam = 'CMO';
        partner.ambassadorBuddy = 'ambassador buddy text';
        partner.workingDestinations = new List<TIP_Wrappers.WorkingDestinationData>();

        TIP_Wrappers.WorkingDestinationData w1 = new TIP_Wrappers.WorkingDestinationData();
        w1.code = '17';
        w1.Name = 'Venice';
        w1.sapPayeeNumber = '123123123';
        w1.taxExemption = 'true';
        w1.partnerCompliance = 'true';
        partner.workingDestinations.add(w1);

        TIP_Wrappers.WorkingDestinationData w2 = new TIP_Wrappers.WorkingDestinationData();
        w2.code = '63';
        w2.Name = 'Paris';
        w2.sapPayeeNumber = '123123123';
        w2.taxExemption = 'false';
        w2.partnerCompliance = 'false';
        partner.workingDestinations.add(w2);

        partner.contacts = new List<TIP_Wrappers.ContactData>();
        TIP_Wrappers.ContactData c1 = new TIP_Wrappers.ContactData();
        c1.externalId = 'Test1';
        c1.salutation = 'Mr.';
        c1.firstName = 'Jacky';
        c1.lastName = 'Jones';
        c1.firstNameNative = 'Lan';
        c1.lastNameNative = 'Wangji';
        c1.countryOfTaxResidence = 'CN';
        c1.state = 'Beijing';
        c1.nationality = 'CN';
        c1.passportNumber = 'E00000000';
        c1.validityDate = '2023-01-01';
        c1.passportAuthority = 'test value1';
        c1.passportPlace = 'test place1';
        c1.visaNumber = '4561353135135';
        c1.visaValidityDate = '2023-02-07';
        c1.countryCodeMobilePhone = '86';
        c1.mobilePhone = '1065529988';
        c1.countryCodeOtherPhone1 = '86';
        c1.phone = '13910998888';
        c1.countryCodeOtherPhone2 = '86';
        c1.otherPhone2 = '13910998889';
        c1.countryCodeWeChat = '86';
        c1.weChatNumber = '564861464624898176132';
        c1.weChatId = '0a6s0d8asd4a6sd84a0sd8as60d4';
        c1.email = 'test1mail@mail.mail';
        c1.mailingAddressLine1 = 'line 01';
        c1.mailingAddressLine2 = 'line 02   ';
        c1.mailingAddressLine3 = 'line 03';
        c1.postalCode = '100000';
        c1.role = 'Others';

        partner.contacts.add(c1);

        requestData.add(partner); 

        TIP_Wrappers.PartnerData partner2 = new TIP_Wrappers.PartnerData();
        partner2.externalId = 'Test2';
        partner2.name = 'Test Acc2';
        partner2.ownerId = UserInfo.getUserName();
        partner2.shortName = 'Test Acc2';
        partner2.majorCustomerNationality = 'CN';
        partner2.countryCodeMobile = '212';
        partner2.phone = '123123123';
        partner2.businessType = 'TL';
        partner2.partnerType = 'Individual Partner';
        partner2.partnerStartDate = '2019-10-03';
        partner2.partnerEndDate = '2049-12-31';
        partner2.dfsAccountTeam = 'CMO';
        partner2.ambassadorBuddy = 'ambassador buddy text';
        partner2.workingDestinations = new List<TIP_Wrappers.WorkingDestinationData>();

        TIP_Wrappers.WorkingDestinationData w3 = new TIP_Wrappers.WorkingDestinationData();
        w3.code = '17';
        w3.Name = 'Venice';
        w3.sapPayeeNumber = '123123123';
        w3.taxExemption = 'true';
        w3.partnerCompliance = 'true';
        partner2.workingDestinations.add(w3);

        TIP_Wrappers.WorkingDestinationData w4 = new TIP_Wrappers.WorkingDestinationData();
        w4.code = '63';
        w4.Name = 'Paris';
        w4.sapPayeeNumber = '123123123';
        w4.taxExemption = 'false';
        w4.partnerCompliance = 'false';
        partner2.workingDestinations.add(w4);

        partner2.contacts = new List<TIP_Wrappers.ContactData>();
        TIP_Wrappers.ContactData c2 = new TIP_Wrappers.ContactData();
        c2.externalId = 'Test2';
        c2.salutation = 'Mr.';
        c2.firstName = 'Jacky';
        c2.lastName = 'Jones';
        c2.firstNameNative = 'Wei';
        c2.lastNameNative = 'Wuxian';
        c2.countryOfTaxResidence = 'CN';
        c2.state = 'Beijing';
        c2.nationality = 'CN';
        c2.passportNumber = 'E00000000';
        c2.validityDate = '2023-01-01';
        c2.passportAuthority = 'test value1';
        c2.passportPlace = 'test place1';
        c2.visaNumber = '4561353135135';
        c2.visaValidityDate = '2023-02-07';
        c2.countryCodeMobilePhone = '86';
        c2.mobilePhone = '1065529988';
        c2.countryCodeOtherPhone1 = '86';
        c2.phone = '13910998888';
        c2.countryCodeOtherPhone2 = '86';
        c2.otherPhone2 = '13910998889';
        c2.countryCodeWeChat = '86';
        c2.weChatNumber = '564861464624898176132';
        c2.weChatId = '0a6s0d8asd4a6sd84a0sd8as60d4';
        c2.email = 'test1mail@mail.mail';
        c2.mailingAddressLine1 = 'line 01';
        c2.mailingAddressLine2 = 'line 02   ';
        c2.mailingAddressLine3 = 'line 03';
        c2.postalCode = '100000';
        c2.role = 'Others';

        partner2.contacts.add(c2);

        requestData.add(partner2); 

        return requestData;

    }

    private static void insertAccount(){
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
            Short_name__c = 'TIM Test',
            TIP_Account_External_Id__c = 'Test1'
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
    private static void testCreation() {

        List<TIP_Wrappers.PartnerData> requestData = genericJSON();

        Test.startTest();
        List<TIP_Wrappers.PartnerRestResponse> response = TIP_REST_CreatePartner.doPost('LFG', false, requestData);
        Test.stopTest();

        List<Account> newPartners = [SELECT Id FROM Account];

        System.assertNotEquals(null, response);
        System.assertEquals(response.size(), 2);
        System.assertEquals(newPartners.size(), 2);

    }

    @isTest
    private static void testUpdate() {

        insertAccount();

        List<TIP_Wrappers.PartnerData> requestData = genericJSON();
        List<TIP_Wrappers.PartnerData> request1 = new List<TIP_Wrappers.PartnerData>();
        TIP_Wrappers.PartnerData partner = new TIP_Wrappers.PartnerData();
        partner.externalId = 'Test1';
        partner.workingDestinations = new List<TIP_Wrappers.WorkingDestinationData>();
        TIP_Wrappers.WorkingDestinationData wdUpd = requestData.get(0).workingDestinations.get(0);
        wdUpd.taxExemption = 'false';
        partner.workingDestinations.add(wdUpd);
        partner.contacts = new List<TIP_Wrappers.ContactData>();
        TIP_Wrappers.ContactData cUpd = requestData.get(0).contacts.get(0);
        cUpd.validityDate = '2019-01-01';
        partner.contacts.add(cUpd);
        request1.add(partner);

        Test.startTest();
        List<TIP_Wrappers.PartnerRestResponse> response = TIP_REST_CreatePartner.doPut('LFG', false, request1);
        Test.stopTest();

        List<Account> newPartners = [SELECT Id FROM Account];

        System.assertNotEquals(null, response);

    }

    @isTest static void testErrorPartnerRequiredField() {

        List<TIP_Wrappers.PartnerData> requestData = genericJSON();
        TIP_Wrappers.PartnerData damagedPartner1 = requestData.get(0);
        damagedPartner1.name = '';

        TIP_Wrappers.PartnerData damagedPartner2 = requestData.get(0);
        damagedPartner2.workingDestinations = null;

        List<TIP_Wrappers.PartnerData> request1 = new List<TIP_Wrappers.PartnerData>{damagedPartner1, damagedPartner2};
        Test.startTest();
        List<TIP_Wrappers.PartnerRestResponse> response = TIP_REST_CreatePartner.doPost('LFG', false, request1);
        Test.stopTest();

        List<Account> newPartners = [SELECT Id FROM Account];
        System.assertEquals(newPartners.size(), 0);

    }

    @isTest static void testErrorPartnerFieldsFormat() {

        List<TIP_Wrappers.PartnerData> requestData = genericJSON();
        TIP_Wrappers.PartnerData damagedPartner1 = requestData.get(0);
        damagedPartner1.ownerId = 'invalid@dfs.com';
        damagedPartner1.parentAccountExternalId = 'none';
        damagedPartner1.majorCustomerNationality = 'Utopian';

        List<TIP_Wrappers.PartnerData> request1 = new List<TIP_Wrappers.PartnerData>{damagedPartner1};
        Test.startTest();
        List<TIP_Wrappers.PartnerRestResponse> response = TIP_REST_CreatePartner.doPost('LFG', false, request1);
        Test.stopTest();

        List<Account> newPartners = [SELECT Id FROM Account];
        System.assertEquals(newPartners.size(), 0);
    }

    @isTest static void testErrorPartnerDuplicates() {
        List<TIP_Wrappers.PartnerData> requestData = genericJSON();
        List<TIP_Wrappers.PartnerData> request1 = new List<TIP_Wrappers.PartnerData>{requestData.get(0)};

        Test.startTest();
        //success
        List<TIP_Wrappers.PartnerRestResponse> response = TIP_REST_CreatePartner.doPost('LFG', false, request1);
        
        //duplicate
        TIP_Wrappers.PartnerData duplicatePartner1 = requestData.get(0);
        //duplicatePartner1.externalId = 'TestDup1';
        List<TIP_Wrappers.PartnerData> request2 = new List<TIP_Wrappers.PartnerData>{duplicatePartner1};
        List<TIP_Wrappers.PartnerRestResponse> response1 = TIP_REST_CreatePartner.doPost('LFG', false, request2);
        Test.stopTest();

        List<Account> newPartners = [SELECT Id FROM Account];
        System.assertEquals(newPartners.size(), 1);
    }

    @isTest static void testErrorWD() {

        List<TIP_Wrappers.PartnerData> requestData = genericJSON();
        TIP_Wrappers.PartnerData damagedPartner1 = requestData.get(0);
        List<TIP_Wrappers.WorkingDestinationData> list1 = new List<TIP_Wrappers.WorkingDestinationData>();

        TIP_Wrappers.WorkingDestinationData w1 = new TIP_Wrappers.WorkingDestinationData();
        w1.code = '17';
        w1.Name = 'Venice';
        w1.sapPayeeNumber = '123123123';
        w1.taxExemption = 'true';
        w1.partnerCompliance = 'true';
        list1.add(w1);

        TIP_Wrappers.WorkingDestinationData w2 = new TIP_Wrappers.WorkingDestinationData();
        w2.code = '25';
        w2.Name = 'Venice';
        w2.sapPayeeNumber = '123123123';
        w2.taxExemption = 'false';
        w2.partnerCompliance = 'false';
        list1.add(w2);  

        damagedPartner1.workingDestinations = list1;


        TIP_Wrappers.PartnerData damagedPartner2 = requestData.get(0);
        List<TIP_Wrappers.WorkingDestinationData> list2 = new List<TIP_Wrappers.WorkingDestinationData>();

        TIP_Wrappers.WorkingDestinationData w3 = new TIP_Wrappers.WorkingDestinationData();
        w3.code = '17';
        w3.Name = '';
        w3.sapPayeeNumber = '123123123';
        w3.taxExemption = 'qqqq';
        w3.partnerCompliance = 'true';
        list2.add(w3);

        TIP_Wrappers.WorkingDestinationData w4 = new TIP_Wrappers.WorkingDestinationData();
        w4.code = '63';
        w4.Name = 'Venice';
        w4.sapPayeeNumber = '123123123';
        w4.taxExemption = 'false';
        w4.partnerCompliance = 'false';
        w4.cmsCode = '12345';
        list2.add(w4);
        
        TIP_Wrappers.WorkingDestinationData w5 = new TIP_Wrappers.WorkingDestinationData();
        w5.code = '63';
        w5.Name = 'Venice123123';
        w5.sapPayeeNumber = '123123123';
        w5.taxExemption = 'false';
        w5.partnerCompliance = 'false';
        w4.cmsCode = '12345';
        list2.add(w5);

        damagedPartner2.workingDestinations = list2;

        List<TIP_Wrappers.PartnerData> request1 = new List<TIP_Wrappers.PartnerData>{damagedPartner1, damagedPartner2};
        Test.startTest();
        List<TIP_Wrappers.PartnerRestResponse> response = TIP_REST_CreatePartner.doPost('LFG', false, request1);
        Test.stopTest();

        List<Account> newPartners = [SELECT Id FROM Account];
        System.assertEquals(newPartners.size(), 0);

    }

    @isTest static void testErrorContact() {

        List<TIP_Wrappers.PartnerData> requestData = genericJSON();
        TIP_Wrappers.PartnerData damagedPartner1 = requestData.get(0);
        TIP_Wrappers.ContactData c1 = damagedPartner1.contacts.get(0);
        c1.lastName = '';
        c1.validityDate = 'daasdasd';
        c1.salutation = 'Senior';
        c1.countryCodeMobilePhone = '-';
        c1.countryCodeOtherPhone1 = '-';
        c1.countryCodeOtherPhone2 = '-';
        c1.countryCodeWeChat = '-';
        c1.nationality = 'Utopian';
        c1.countryOfTaxResidence = 'Utopia';

        TIP_Wrappers.PartnerData damagedPartner2 = requestData.get(1); // individual
        damagedPartner2.contacts = null;

        List<TIP_Wrappers.PartnerData> request1 = new List<TIP_Wrappers.PartnerData>{damagedPartner1, damagedPartner2};
        Test.startTest();
        List<TIP_Wrappers.PartnerRestResponse> response = TIP_REST_CreatePartner.doPost('LFG', false, request1);
        Test.stopTest();

        List<Account> newPartners = [SELECT Id FROM Account];
        System.assertEquals(newPartners.size(), 0);
    }
}
