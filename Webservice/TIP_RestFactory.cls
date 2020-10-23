/**
 * @author      Anna Filimonova
 * @date        12/03/2020
 * @group       DFS-SFDC
 * @description Factory class to generate miscelanious items with different parameters
 */
public with sharing class TIP_RestFactory {

    /** TIP Account record type id */
    public static final String TIP_ACCOUNT_RT = Schema.SObjectType.Account.getRecordTypeInfosByName().get(CRM_Constants.TIP_RECORD_TYPE).getRecordTypeId();
    /** TIP Contact record type id */
    private static final String TIP_CONTACT_RT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(CRM_Constants.TIP_RECORD_TYPE).getRecordTypeId();
    /** Instance of items generator */
    private static ItemFactory generator = new ItemFactory();
    
    /**
     * @description generate brand new TIP_RestFactory.PartnerItem wrapper without errors.
     * @param record contains partner data.
     * @return TIP_RestFactory.PartnerItem new TIP_RestFactory.PartnerItem instance. 
     */
    public static TIP_RestFactory.PartnerItem newItem(TIP_Wrappers.PartnerData record) {
        return generator.newItem(record);
    }

    /**
     * @description generate brand new TIP_RestFactory.PartnerItem wrapper with error(s).
     * @param record contains partner data.
     * @return TIP_RestFactory.PartnerItem new TIP_RestFactory.PartnerItem instance. 
     */
    public static TIP_RestFactory.PartnerItem newItemWithError(TIP_Wrappers.PartnerData record, String error) {
        return generator.newItemWithError(record, error);
    }

    /**
     * @description Generate new TIP_RestFactory.PartnerItem wrapper with error duplicate external id.
     * @param record contains partner data.
     * @return TIP_RestFactory.PartnerItem new TIP_RestFactory.PartnerItem instance. 
     */
    public static TIP_RestFactory.PartnerItem newItemWithDuplicateExtId(TIP_Wrappers.PartnerData record) {
        String errMesg = String.format(
            TIP_ValidatorUtil.DUPLICATE_EXT_ID_IN_REQUEST, 
            new List<String>{record.externalId}
        );
        return newItemWithError(record, errMesg);
    }

    /**
     * @description Create an instance of account based on TIP_Wrappers.PartnerData wrapper.
     * @param partner partner data wrapper.
     * @return Instance of account. 
     */
    public static Account createAccount(TIP_Wrappers.PartnerData partnerWrap) {
        Account partnerRecord = new Account();
        partnerRecord.RecordTypeId = TIP_ACCOUNT_RT;
        partnerRecord.TIP_Account_External_Id__c = partnerWrap.externalId;
        if (!String.isBlank(partnerWrap.name)) {
            partnerRecord.Name = partnerWrap.name;
        }
        if (!String.isBlank(partnerWrap.ownerId)) {
            partnerRecord.OwnerId = partnerWrap.ownerId;
        }
        if (!String.isBlank(partnerWrap.shortName)) {
            partnerRecord.Short_name__c = partnerWrap.shortName;
        }
        if (!String.isBlank(partnerWrap.parentAccountExternalId)) {
            partnerRecord.ParentId = partnerWrap.parentAccountExternalId;
        }
        if (!String.isBlank(partnerWrap.majorCustomerNationality)) {
            partnerRecord.Major_customer_nationality_passport__c = partnerWrap.majorCustomerNationality;
        }
        if (!String.isBlank(partnerWrap.countryCodeMobile)) {
            partnerRecord.Country_Code__c = partnerWrap.countryCodeMobile;
        }
        if (!String.isBlank(partnerWrap.phone)) {
            partnerRecord.Phone = partnerWrap.phone;
        }
        if (!String.isBlank(partnerWrap.businessType)) {
            partnerRecord.Business_type__c = partnerWrap.businessType;
        }
        if (!String.isBlank(partnerWrap.partnerType)) {
            partnerRecord.Partner_type__c = partnerWrap.partnerType;
        }
        if (!String.isBlank(partnerWrap.partnerStartDate)) {
            partnerRecord.Partner_start_date__c = Date.ValueOf(partnerWrap.partnerStartDate);
        }
        if (!String.isBlank(partnerWrap.partnerEndDate)) {
            partnerRecord.Partner_end_date__c = Date.valueOf(partnerWrap.partnerEndDate);
        }
        if (!String.isBlank(partnerWrap.dfsAccountTeam)) {
            partnerRecord.DFS_account_team__c = partnerWrap.dfsAccountTeam;
        }
        if (!String.isBlank(partnerWrap.ambassadorBuddy)) {
            partnerRecord.Ambassador_Buddy__c = partnerWrap.ambassadorBuddy;
        }
        return partnerRecord;
    }
    /**
     * @description Create an instance of TIP_Working_Destination__c based on TIP_Wrappers.WorkingDestinationData wrapper.
     * @param partnerExternalId parent partner external id.
     * @param wdWrap working destionation data wrapper.
     * @return Instance of TIP_Working_Destination__c. 
     */
    public static TIP_Working_Destination__c createWorkingDestination(String partnerExternalId, TIP_Wrappers.WorkingDestinationData wdWrap) {
        TIP_Working_Destination__c wdRecord = new TIP_Working_Destination__c();
        wdRecord.External_ID__c = partnerExternalId + '-' + wdWrap.code;
        wdRecord.Code__c = wdWrap.code;
        if (!String.isBlank(wdWrap.Name)) {
            wdRecord.Name = wdWrap.Name;
            wdRecord.Working_Destination__c = wdWrap.Name;
        }
        if (!String.isBlank(wdWrap.cmsCode)) {
            wdRecord.CMS_code__c = wdWrap.cmsCode;
        }
        if (!String.isBlank(wdWrap.sapPayeeNumber)) {
            wdRecord.SAP_Payee_Number__c = wdWrap.sapPayeeNumber;
        }
        if (!String.isBlank(wdWrap.taxExemption)) {
            wdRecord.Tax_Exemption__c = Boolean.valueOf(wdWrap.taxExemption);
        }
        if (!String.isBlank(wdWrap.partnerCompliance)) {
            wdRecord.Partner_Compliance__c = Boolean.valueOf(wdWrap.partnerCompliance);
        }
        return wdRecord;
    }
    /**
     * @description Create an instance of contact based on TIP_Wrappers.ContactData wrapper.
     * @param contactWrap contact data wrapper.
     * @param partnerType corporate or individual.
     * @return Instance of contact. 
     */
    public static Contact createContact(TIP_Wrappers.ContactData contactWrap, String partnerType) {
        Contact contactRecord = new Contact();
        contactRecord.RecordTypeId = TIP_CONTACT_RT;
        contactRecord.TIP_External_ID__c = contactWrap.externalId;
        if (!String.isBlank(contactWrap.firstName)) {
            contactRecord.FirstName = contactWrap.firstName;
        }
        if (!String.isBlank(contactWrap.lastName)) {
            contactRecord.LastName = contactWrap.lastName;
        }
        if (!String.isBlank(contactWrap.firstNameNative)) {
            contactRecord.First_Name_Native__c = contactWrap.firstNameNative;
        }
        if (!String.isBlank(contactWrap.lastNameNative)) {
            contactRecord.Last_Name_Native__c = contactWrap.lastNameNative;
        }
        if (!String.isBlank(contactWrap.countryOfTaxResidence)) {
            contactRecord.TIP_Nationality__c = contactWrap.countryOfTaxResidence;
        }
        if (!String.isBlank(contactWrap.state)) {
            contactRecord.TIP_State__c = contactWrap.state;
        }
        if (!String.isBlank(contactWrap.nationality)) {
            contactRecord.TIP_Country__c = contactWrap.nationality;
        }
        if (!String.isBlank(contactWrap.passportNumber)) {
            contactRecord.Passport_number__c = contactWrap.passportNumber;
        }
        if (!String.isBlank(contactWrap.validityDate)) {
            contactRecord.Validity_date__c = Date.valueOf(contactWrap.validityDate);
        }
        if (!String.isBlank(contactWrap.passportAuthority)) {
            contactRecord.TIP_Passport_Authority__c = contactWrap.passportAuthority;
        }
        if (!String.isBlank(contactWrap.passportPlace)) {
            contactRecord.TIP_Passport_Place__c = contactWrap.passportPlace;
        }
        if (!String.isBlank(contactWrap.visaNumber)) {
            contactRecord.Visa_number__c = contactWrap.visaNumber;
        }
        if (!String.isBlank(contactWrap.visaValidityDate)) {
            contactRecord.Visa_Validity_date__c = Date.valueOf(contactWrap.visaValidityDate);
        }
        if (!String.isBlank(contactWrap.countryCodeMobilePhone)) {
            contactRecord.Dialling_Code_Mobile_Phone__c = contactWrap.countryCodeMobilePhone;
        }
        if (!String.isBlank(contactWrap.mobilePhone)) {
            contactRecord.MobilePhone = contactWrap.mobilePhone;
        }
        if (!String.isBlank(contactWrap.countryCodeOtherPhone1)) {
            contactRecord.Dialling_Code_Other_Phone_1__c = contactWrap.countryCodeOtherPhone1;
        }
        if (!String.isBlank(contactWrap.phone)) {
            contactRecord.Phone = contactWrap.phone;
        }
        if (!String.isBlank(contactWrap.countryCodeOtherPhone2)) {
            contactRecord.Dialling_Code_Other_Phone_2__c = contactWrap.countryCodeOtherPhone2;
        }
        if (!String.isBlank(contactWrap.otherPhone2)) {
            contactRecord.OtherPhone = contactWrap.otherPhone2;
        }
        if (!String.isBlank(contactWrap.countryCodeWeChat)) {
            contactRecord.Country_Code_WeChat__c = contactWrap.countryCodeWeChat;
        }
        if (!String.isBlank(contactWrap.weChatNumber)) {
            contactRecord.WeChat_number__c = contactWrap.weChatNumber;
        }
        if (!String.isBlank(contactWrap.weChatId)) {
            contactRecord.WeChat_ID__c = contactWrap.weChatId;
        }
        if (!String.isBlank(contactWrap.email)) {
            contactRecord.Email = contactWrap.email;
        }
        if (!String.isBlank(contactWrap.mailingAddressLine1)) {
            contactRecord.Mailing_Address_Line_1__c = contactWrap.mailingAddressLine1;
        }
        if (!String.isBlank(contactWrap.mailingAddressLine2)) {
            contactRecord.Mailing_Address_Line_2__c = contactWrap.mailingAddressLine2;
        }
        if (!String.isBlank(contactWrap.mailingAddressLine3)) {
            contactRecord.Mailing_Address_Line_3__c = contactWrap.mailingAddressLine3;
        }
        if (!String.isBlank(contactWrap.postalCode)) {
            contactRecord.Other_Zip_Code__c = contactWrap.postalCode;
        }
        if (!String.isBlank(contactWrap.role) && !String.isBlank(partnerType)) {
            if (partnerType.equals(CRM_Constants.INDIVIDUAL_PARTNER)) {
                contactRecord.TIP_Individual_Role__c = contactWrap.role;
            } else {
                contactRecord.Role__c = contactWrap.role;
            }
        }
        return contactRecord;
    }
    /**
     * @description Create an instance of partner wrapper based on Account record.
     * @param partner partner data wrapper.
     * @return Instance of account. 
     */
    public static TIP_Wrappers.PartnerData createPartnerWrap(Account partnerRecord) {
        TIP_Wrappers.PartnerData partnerWrap = new TIP_Wrappers.PartnerData();
        //partnerRecord.RecordTypeId = TIP_ACCOUNT_RT;
        partnerWrap.externalId = partnerRecord.TIP_Account_External_Id__c;
        if (!String.isBlank(partnerRecord.Name)) {
            partnerWrap.name = partnerRecord.Name;
        }
        if (!String.isBlank(partnerRecord.OwnerId)) {
            partnerWrap.ownerId = partnerRecord.Owner.Username;
        }
        if (!String.isBlank(partnerRecord.Short_name__c)) {
            partnerWrap.shortName = partnerRecord.Short_name__c;
        }
        if (!String.isBlank(partnerRecord.ParentId)) {
            partnerWrap.parentAccountExternalId = partnerRecord.Parent.TIP_Account_External_Id__c;
        }
        if (!String.isBlank(partnerRecord.ISO_Code__c)) {
            partnerWrap.majorCustomerNationality = partnerRecord.ISO_Code__c;
        }
        if (!String.isBlank(partnerRecord.Country_Code__c)) {
            partnerWrap.countryCodeMobile = partnerRecord.Country_Code__c;
        }
        if (!String.isBlank(partnerRecord.Phone)) {
            partnerWrap.phone = partnerRecord.Phone;
        }
        if (!String.isBlank(partnerRecord.Business_type__c)) {
            partnerWrap.businessType = partnerRecord.Business_type__c;
        }
        if (!String.isBlank(partnerRecord.Partner_type__c)) {
            partnerWrap.partnerType = partnerRecord.Partner_type__c;
        }
        if (partnerRecord.Partner_start_date__c != null) {
            partnerWrap.partnerStartDate = String.valueOf(partnerRecord.Partner_start_date__c);
        }
        if (partnerRecord.Partner_end_date__c != null) {
            partnerWrap.partnerEndDate = String.valueOf(partnerRecord.Partner_end_date__c);
        }
        if (!String.isBlank(partnerRecord.DFS_account_team__c)) {
            partnerWrap.dfsAccountTeam = partnerRecord.DFS_account_team__c;
        }
        if (!String.isBlank(partnerRecord.Ambassador_Buddy__c)) {
            partnerWrap.ambassadorBuddy = partnerRecord.Ambassador_Buddy__c;
        }
        if (partnerRecord.TIP_Working_Destinations__r != null) {
            partnerWrap.workingDestinations = new List<TIP_Wrappers.WorkingDestinationData>();
            for (TIP_Working_Destination__c childWD : partnerRecord.TIP_Working_Destinations__r) {
                TIP_Wrappers.WorkingDestinationData wdWrap = createWorkingDestinationWrapper(childWD);
                partnerWrap.workingDestinations.add(wdWrap);
            }
        }
        if (partnerRecord.Contacts != null) {
            partnerWrap.contacts = new List<TIP_Wrappers.ContactData>();
            for (Contact childContact : partnerRecord.Contacts) {
                TIP_Wrappers.ContactData contactWrap = createContactWrap(childContact);
                partnerWrap.contacts.add(contactWrap);
            }
        }
        return partnerWrap;
    }
    /**
     * @description Create an instance of working destination wrapper based on TIP_Working_Destination__c record.
     * @param wdRecord TIP_Working_Destination__c record.
     * @return working destination wrapper. 
     */
    public static TIP_Wrappers.WorkingDestinationData createWorkingDestinationWrapper(TIP_Working_Destination__c wdRecord) {
        TIP_Wrappers.WorkingDestinationData wdWrap = new TIP_Wrappers.WorkingDestinationData();
        if (!String.isBlank(wdRecord.Code__c)) {
            wdWrap.code = wdRecord.Code__c;
        }
        if (!String.isBlank(wdRecord.Working_Destination__c)) {
            wdWrap.Name = wdRecord.Working_Destination__c;
        }
        if (!String.isBlank(wdRecord.CMS_code__c)) {
            wdWrap.cmsCode = wdRecord.CMS_code__c;
        }
        if (!String.isBlank(wdRecord.SAP_Payee_Number__c)) {
            wdWrap.sapPayeeNumber = wdRecord.SAP_Payee_Number__c;
        }
        wdWrap.taxExemption = wdRecord.Tax_Exemption__c != null ? String.valueOf(wdRecord.Tax_Exemption__c) : 'false';
        wdWrap.partnerCompliance = wdRecord.Partner_Compliance__c != null ? String.valueOf(wdRecord.Partner_Compliance__c) : 'false';
        return wdWrap;
    }
    /**
     * @description Create an instance of TIP_Wrappers.ContactData wrapper based on Contact record.
     * @param contactRecord contact record.
     * @return Instance of TIP_Wrappers.ContactData. 
     */
    public static TIP_Wrappers.ContactData createContactWrap(Contact contactRecord) {
        TIP_Wrappers.ContactData contactWrap = new TIP_Wrappers.ContactData();
        if (!String.isBlank(contactRecord.TIP_External_ID__c)) {
            contactWrap.externalId = contactRecord.TIP_External_ID__c;
        }
        if (!String.isBlank(contactRecord.FirstName)) {
            contactWrap.firstName = contactRecord.FirstName;
        }
        if (!String.isBlank(contactRecord.LastName)) {
            contactWrap.lastName = contactRecord.LastName;
        }
        if (!String.isBlank(contactRecord.First_Name_Native__c)) {
            contactWrap.firstNameNative = contactRecord.First_Name_Native__c;
        }
        if (!String.isBlank(contactRecord.Last_Name_Native__c)) {
            contactWrap.lastNameNative = contactRecord.Last_Name_Native__c;
        }
        if (!String.isBlank(contactRecord.TIP_Country_ISO_Code__c)) {
            contactWrap.countryOfTaxResidence = contactRecord.TIP_Country_ISO_Code__c;
        }
        if (!String.isBlank(contactRecord.TIP_State__c)) {
            contactWrap.state = contactRecord.TIP_State__c;
        }
        if (!String.isBlank(contactRecord.TIP_Nationality_ISO_Code__c)) {
            contactWrap.nationality = contactRecord.TIP_Nationality_ISO_Code__c;
        }
        if (!String.isBlank(contactRecord.Passport_number__c)) {
            contactWrap.passportNumber = contactRecord.Passport_number__c;
        }
        if (contactRecord.Validity_date__c != null) {
            contactWrap.validityDate = String.valueOf(contactRecord.Validity_date__c);
        }
        if (!String.isBlank(contactRecord.TIP_Passport_Authority__c)) {
            contactWrap.passportAuthority = contactRecord.TIP_Passport_Authority__c;
        }
        if (!String.isBlank(contactRecord.TIP_Passport_Place__c)) {
            contactWrap.passportPlace = contactRecord.TIP_Passport_Place__c;
        }
        if (!String.isBlank(contactRecord.Visa_number__c)) {
            contactWrap.visaNumber = contactRecord.Visa_number__c;
        }
        if (contactRecord.Visa_Validity_date__c != null) {
            contactWrap.visaValidityDate = String.valueOf(contactRecord.Visa_Validity_date__c);
        }
        if (!String.isBlank(contactRecord.Dialling_Code_Mobile_Phone__c)) {
            contactWrap.countryCodeMobilePhone = contactRecord.Dialling_Code_Mobile_Phone__c;
        }
        if (!String.isBlank(contactRecord.MobilePhone)) {
            contactWrap.mobilePhone = contactRecord.MobilePhone;
        }
        if (!String.isBlank(contactRecord.Dialling_Code_Other_Phone_1__c)) {
            contactWrap.countryCodeOtherPhone1 = contactRecord.Dialling_Code_Other_Phone_1__c;
        }
        if (!String.isBlank(contactRecord.Phone)) {
            contactWrap.phone = contactRecord.Phone;
        }
        if (!String.isBlank(contactRecord.Dialling_Code_Other_Phone_2__c)) {
            contactWrap.countryCodeOtherPhone2 = contactRecord.Dialling_Code_Other_Phone_2__c;
        }
        if (!String.isBlank(contactRecord.OtherPhone)) {
            contactWrap.otherPhone2 = contactRecord.OtherPhone;
        }
        if (!String.isBlank(contactRecord.Country_Code_WeChat__c)) {
            contactWrap.countryCodeWeChat = contactRecord.Country_Code_WeChat__c;
        }
        if (!String.isBlank(contactRecord.WeChat_number__c)) {
            contactWrap.weChatNumber = contactRecord.WeChat_number__c;
        }
        if (!String.isBlank(contactRecord.WeChat_ID__c)) {
            contactWrap.weChatId = contactRecord.WeChat_ID__c;
        }
        if (!String.isBlank(contactRecord.Email)) {
            contactWrap.email = contactRecord.Email;
        }
        if (!String.isBlank(contactRecord.Mailing_Address_Line_1__c)) {
            contactWrap.mailingAddressLine1 = contactRecord.Mailing_Address_Line_1__c;
        }
        if (!String.isBlank(contactRecord.Mailing_Address_Line_2__c)) {
            contactWrap.mailingAddressLine2 = contactRecord.Mailing_Address_Line_2__c;
        }
        if (!String.isBlank(contactRecord.Mailing_Address_Line_3__c)) {
            contactWrap.mailingAddressLine3 = contactRecord.Mailing_Address_Line_3__c;
        }
        if (!String.isBlank(contactRecord.Other_Zip_Code__c)) {
            contactWrap.postalCode = contactRecord.Other_Zip_Code__c;
        }
        if (!String.isBlank(contactRecord.TIP_Individual_Role__c) || !String.isBlank(contactRecord.Role__c)) {
            contactWrap.role = !String.isBlank(contactRecord.TIP_Individual_Role__c) ? contactRecord.TIP_Individual_Role__c : contactRecord.Role__c;
        }
        return contactWrap;
    }
    /**
     * @description Set item as invalid and record error message
     * @param item PartnerItem container.
     * @param errorMessage error info.
     * @return - 
     */
    public static void setError(PartnerItem item, String errorMessage) {
        item.setError(errorMessage);
    }



    /**
     * @author      Anna Filimonova
     * @date        12/03/2020
     * @group       DFS-SFDC
     * @description Inner class for items generation
     */
    class ItemFactory {

        /**
        * @description generate brand new PartnerItem wrapper without errors.
        * @param record contains partner data.
        * @return PartnerItem new PartnerItem instance. 
        */
        public TIP_RestFactory.PartnerItem newItem(TIP_Wrappers.PartnerData record) {
            return new TIP_RestFactory.PartnerItem(record);
        }

        /**
        * @description generate brand new TIP_RestFactory.PartnerItem wrapper with error(s).
        * @param record contains partner data.
        * @return TIP_RestFactory.PartnerItem new TIP_RestFactory.PartnerItem instance. 
        */
        public TIP_RestFactory.PartnerItem newItemWithError(TIP_Wrappers.PartnerData record, String error) {
            return new TIP_RestFactory.PartnerItem(record, false, error);
        }
    }

    /**
     * @author      Anna Filimonova
     * @date        12/03/2020
     * @group       DFS-SFDC
     * @description Container to work with validations
     */
    public class PartnerItem {
        public TIP_Wrappers.PartnerData record { get; set; }
        public Boolean isError { get; set; }
        public List<String> errMesg { get; set; } 
        public String sfId { get; set; }

        PartnerItem(TIP_Wrappers.PartnerData record) {
            this(record, true);
        }

        PartnerItem(TIP_Wrappers.PartnerData record, Boolean isCorrect) {
            this(record, isCorrect, new List<String>());
        }

        PartnerItem(TIP_Wrappers.PartnerData record, Boolean isCorrect, String errMesg) {
            this(record, isCorrect, new List<String>{errMesg});
        }

        PartnerItem(TIP_Wrappers.PartnerData record, Boolean isCorrect, List<String> errMesg) {
            this.record = record;
            this.isError = !isCorrect;
            this.errMesg = new List<String>();
            this.errMesg.addAll(errMesg);
        }

        void setError(String errMesg) {
            this.isError = true;
            if (this.errMesg == null) {
                this.errMesg = new List<String>();
            }
            this.errMesg.add(errMesg);
        }
    }

}