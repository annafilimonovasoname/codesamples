/**
 * @author      Anna Filimonova
 * @date        10/03/2020
 * @group       DFS-SFDC
 * @description Helper class for partner REST API validations
 */

public with sharing class TIP_RestPartnerValidator {

    /** Validator operator instance that implements different validations based on operation. */
    private TIP_ValidatorUtil validator;

    /** CREATE or UPDATE */
    private String restOperation;

    private Map<String, Account> existingAccounts;

    private Boolean isUpdate = false;

    /**
     * @description Creates instance of TIP_RestPartnerValidator and initializes validator based on operation.
     * @param -
     * @return instance of TIP_RestPartnerValidator. 
     */
    public TIP_RestPartnerValidator(String operation) {
        validator = TIP_ValidatorUtil.getInstance(operation);
        restOperation = operation;
        existingAccounts = new Map<String, Account>();
    }

    /**
     * @description For UPDATE operation only: creates a Map of existing accoounts.
     * @param -
     * @return instance of TIP_RestPartnerValidator. 
     */
    public void initForUpdate(List<Account> accounts) {
        isUpdate = true;
        if (accounts != null && !accounts.isEmpty()) {
            for (Account a : accounts) {
                existingAccounts.put(a.TIP_Account_External_Id__c, a);
            }
        }
    }

    /**
     * @description First step of validations. 
     * Checks required fields on partner and working destination level.
     * @param partnerRecord partner information
     * @return String consolidated list of all errors on the provided records. 
     */
    public String doSanityCheck(TIP_Wrappers.PartnerData partnerRecord) {
        String sanityErrorMessage = '';

        //validate if partner exists for update
        if (isUpdate && existingAccounts.get(partnerRecord.externalId) == null) {
            sanityErrorMessage = String.format(TIP_ValidatorUtil.INVALID_EXTERNAL_ID, new List<String>{partnerRecord.externalId});
            return sanityErrorMessage;
        }

        List<String> missingFields = getMissingRequiredFields(partnerRecord);

        //validate partner fields
        if (!missingFields.isEmpty()) {
            sanityErrorMessage = validator.getEmptyFieldError(missingFields);
            return sanityErrorMessage;
        }

        if (isUpdate) {
            List<String> changedStaticFields = checkForbiddenFieldsForUpdate(partnerRecord);
            if (!changedStaticFields.isEmpty()) {
                sanityErrorMessage = String.format(
                    TIP_ValidatorUtil.FIELD_CANNOT_BE_UPDATED, 
                    new List<String>{'Partner Account', String.join(changedStaticFields, ', ')});
                return sanityErrorMessage;
            }
        }

        //validate working destination fields
        sanityErrorMessage = validateWorkingDestinations(partnerRecord);
        if (!String.isEmpty(sanityErrorMessage)) {
            return sanityErrorMessage;
        }

        //validate contact fields
        sanityErrorMessage = validateContacts(partnerRecord);
        if (!String.isEmpty(sanityErrorMessage)) {
            return sanityErrorMessage;
        }

        return sanityErrorMessage;
    }

    /**
     * @description First step of validations. 
     * Checks required fields on partner level and populates 
     * some lists (ownerEmails, parentAccountIds) for further checks.
     * @param partnerRecord partner information
     * @return String consolidated list of all errors on the provided records. 
     */
    private List<String> getMissingRequiredFields(TIP_Wrappers.PartnerData partnerRecord) {
        Map<String, Object> partnerRecordTransformed = TIP_RestHelperUtil.transformJsonToMap(JSON.serialize(partnerRecord));
        Account a = existingAccounts.get(partnerRecord.externalId);
        TIP_RestValidationProcessor val = new TIP_RestValidationProcessor(partnerRecord.externalId);
        List<String> missingRequiredFields = val.getMissingRequiredFields(
            validator, partnerRecordTransformed, 
            TIP_ValidatorUtil.requiredFields_Partner, 
            TIP_ValidatorUtil.fieldsToCollect_Partner
        );
        //collectedValues.putAll(val.collectedValues);
        return missingRequiredFields;
    }

    /**
     * @description First step of validations - UPDATE only. 
     * Checks if fields that can't be updated were changed in request
     * @param partnerRecord partner information
     * @return String consolidated list of all errors on the provided records. 
     */
    private List<String> checkForbiddenFieldsForUpdate(TIP_Wrappers.PartnerData partnerRecord) {
        List<String> invalidFields = new List<String>();

        Account accToUpdate = existingAccounts.get(partnerRecord.externalId);
        if (partnerRecord.ownerId != null && partnerRecord.ownerId != accToUpdate.Owner.Username) {
            invalidFields.add(TIP_Wrappers.Fields_Partner.OWNERID.name());
        }
        if (partnerRecord.businessType != null && partnerRecord.businessType != accToUpdate.Business_type__c) {
            invalidFields.add(TIP_Wrappers.Fields_Partner.BUSINESSTYPE.name());
        }
        if (partnerRecord.partnerType != null && partnerRecord.partnerType != accToUpdate.Partner_type__c) {
            invalidFields.add(TIP_Wrappers.Fields_Partner.PARTNERTYPE.name());
        }
        if (partnerRecord.partnerStartDate != null && partnerRecord.partnerStartDate != String.valueOf(accToUpdate.Partner_start_date__c)) {
            invalidFields.add(TIP_Wrappers.Fields_Partner.PARTNERSTARTDATE.name());
        }
        return invalidFields;
    }

    /**
     * @description First step of validations. 
     * Checks required fields and field format on working destination level.
     * Checks for duplicates in working destination data in terms of 1 record 
     * (can't have 2 working destination with the same name).
     * Populates cmsCodesToAccId Map for further duplicates check.
     * @param partnerRecord partner information
     * @return String consolidated list of all errors on the provided records. 
     */
    private String validateWorkingDestinations(TIP_Wrappers.PartnerData partnerRecord) {
        if (partnerRecord.workingDestinations == null || partnerRecord.workingDestinations.isEmpty()) {
            return isUpdate ? '' : TIP_ValidatorUtil.WORKING_DEST_IS_EMPTY;
        }

        Map<Integer, List<String>> errorListByDestinationIndex = new Map<Integer, List<String>>();
        Map<String, String> validCms = new Map<String, String>();
        for (Integer i = 0; i < partnerRecord.workingDestinations.size(); i++) {
            TIP_Wrappers.WorkingDestinationData wdRecord = partnerRecord.workingDestinations.get(i);
            TIP_Working_Destination__c wdObject = getWDObject(partnerRecord.externalId, wdRecord);
            TIP_RestWorkingDestinationValidator validator = 
                new TIP_RestWorkingDestinationValidator(partnerRecord.externalId, wdRecord, wdObject);
            if (validator.isValid()) {
                //cmsCodesToAccId.put(wdRecord.cmsCode, partnerRecord.externalId);
                validCms.put(wdRecord.cmsCode, partnerRecord.externalId);
            } else {
                errorListByDestinationIndex.put(i, validator.getErrors());
            }
        }

        if (errorListByDestinationIndex.isEmpty()) {
            //all destinations on partner are valid
            TIP_RestWorkingDestinationValidator.validCMSCodesToAccId.putAll(validCms);       
        }

        return formatWDError(errorListByDestinationIndex);
    }

    /**
     * @description Define if it's a new working destination or existing one by unique code
     * @param partnerExternalId partner external id
     * @param wdRecord working destination record from rest request 
     * @return String formatted error. 
     */
    private TIP_Working_Destination__c getWDObject(String partnerExternalId, TIP_Wrappers.WorkingDestinationData wdRecord) {
        TIP_Working_Destination__c wdObjectCurrent;
        if (restOperation != CRM_Constants.WEB_SERVICE_ACTION_CREATE) {
            for (TIP_Working_Destination__c wdObject : existingAccounts.get(partnerExternalId).TIP_Working_Destinations__r) {
                if (wdObject.Code__c == wdRecord.code) {
                    wdObjectCurrent = wdObject;
                    break;
                }
            }
        }
        return wdObjectCurrent;
    }

    /**
     * @description formats general error for all found errors. 
     * @param errorListByDestinationIndex 
     * @return String formatted error. 
     */
    private String formatWDError(Map<Integer, List<String>> errorListByDestinationIndex) {
        if (errorListByDestinationIndex.isEmpty()) {
            return '';
        }

        String errorResult = '';
        for (Integer i : errorListByDestinationIndex.keySet()) {
            errorResult += String.valueOf(i) + ': ' + String.join(errorListByDestinationIndex.get(i), '; ');
        }
        return String.format(TIP_ValidatorUtil.WD_VALIDATION_FAILED, new List<String>{errorResult});
    }

    /**
     * @description First step of validations. 
     * Checks required fields and field format on contact level.
     * Checks for duplicates in contact data in terms of 1 partner record 
     * (can't have 2 contacts with the same external id).
     * @param partnerRecord partner information
     * @return String consolidated list of all errors on the provided records. 
     */
    private String validateContacts(TIP_Wrappers.PartnerData partnerRecord) {
        if (partnerRecord.contacts == null || partnerRecord.contacts.isEmpty()) {
            return (!isUpdate && CRM_Constants.INDIVIDUAL_PARTNER.equals(partnerRecord.partnerType)) ? TIP_ValidatorUtil.CONTACTS_IS_EMPTY : '';
        }

        Map<String, List<String>> errorListByContactExtId = new Map<String, List<String>>();
        for (Integer i = 0; i < partnerRecord.contacts.size(); i++) {
            TIP_Wrappers.ContactData contactRecord = partnerRecord.contacts.get(i);
            contactRecord.externalIdContact = contactRecord.externalId;
            TIP_RestContactValidator validator = 
                new TIP_RestContactValidator(partnerRecord.externalId, contactRecord, restOperation, partnerRecord.partnerType);
            if (!validator.isValid()) {
                errorListByContactExtId.put(contactRecord.externalId, validator.getErrors());
            }
        }
        return formatContactError(errorListByContactExtId);
    }

    /**
     * @description formats general error for all found errors. 
     * @param errorListByDestinationIndex 
     * @return String formatted error. 
     */
    private String formatContactError(Map<String, List<String>> errorListByContact) {
        if (errorListByContact.isEmpty()) {
            return '';
        }

        String errorResult = '';
        for (String i : errorListByContact.keySet()) {
            errorResult += String.valueOf(i) + ': ' + String.join(errorListByContact.get(i), '; ');
        }
        return String.format(TIP_ValidatorUtil.CONTACT_VALIDATION_FAILED, new List<String>{errorResult});
    }

    /**
     * @description Second step of validations. 
     * Checks existing working destinations based on CMS codes info collected on step 1.
     * @param -
     * @return Map<String, String>  Map ofexternal ids of partners with error information.
     */
    public Map<String, String> validateWDDuplicates() {
        Map<String, String> invalidPartnerExtIDs = new Map<String, String>();
        Set<String> cmsCodesToCheck = TIP_RestWorkingDestinationValidator.validCMSCodesToAccId.keySet();
        if (isUpdate) {
            //no need to validate duplicates against updated items
            for (Account a : existingAccounts.values()) {
                for (TIP_Working_Destination__c aWD : a.TIP_Working_Destinations__r) {
                    cmsCodesToCheck.remove(aWD.CMS_Code__c);
                }
            }
        }
        if (cmsCodesToCheck.isEmpty()) {
            return invalidPartnerExtIDs;
        }

        List<TIP_Working_Destination__c> existingWDs = [
            SELECT Name, CMS_Code__c
            FROM TIP_Working_Destination__c
            WHERE CMS_Code__c IN :cmsCodesToCheck
        ];

        Set<String> existingWDsUnique = new Set<String>();

        for (TIP_Working_Destination__c wd : existingWDs) {
            if (existingWDsUnique.contains(wd.CMS_Code__c)) continue;
            String invalidPartnerExtID = TIP_RestWorkingDestinationValidator.validCMSCodesToAccId.get(wd.CMS_Code__c);
            if (invalidPartnerExtID != null) {
                invalidPartnerExtIDs.put(
                    invalidPartnerExtID, 
                    String.format(
                        TIP_ValidatorUtil.DUPLICATE_CMS_WD, 
                        new List<String>{ wd.CMS_Code__c, invalidPartnerExtID }
                    ));
                existingWDsUnique.add(wd.CMS_Code__c);
            }
        }

        return invalidPartnerExtIDs;
    }

    /**
     * @description Second step of validations. 
     * Checks existing contacts based on external ids collected on step 1.
     * @param -
     * @return Map<String, String>  Map of external ids of partners with error information.
     */
    public Map<String, String> validateContactDuplicates() {
        Map<String, String> invalidPartnerExtIDs = new Map<String, String>();

        Set<String> contactExtIdsToCheck = TIP_RestContactValidator.validExtIdToAccId.keySet();
        if (isUpdate) {
            //no need to validate duplicates against updated items
            for (Account a : existingAccounts.values()) {
                for (Contact aContact : a.Contacts) {
                    contactExtIdsToCheck.remove(aContact.TIP_External_ID__c);
                }
            }
        }
        if (contactExtIdsToCheck.isEmpty()) {
            return invalidPartnerExtIDs;
        }

        List<Contact> existingContacts = [
            SELECT Name, TIP_External_ID__c
            FROM Contact
            WHERE TIP_External_ID__c IN :contactExtIdsToCheck
        ];

        for (Contact dupContact : existingContacts) {
            String invalidPartnerExtID = TIP_RestContactValidator.validExtIdToAccId.get(dupContact.TIP_External_ID__c);
            if (invalidPartnerExtID != null) {
                invalidPartnerExtIDs.put(
                    invalidPartnerExtID, 
                    String.format(
                        TIP_ValidatorUtil.DUPLICATE_CONTACT,
                        new List<String>{ dupContact.TIP_External_ID__c, invalidPartnerExtID }
                    ));
            }
        }
        
        return invalidPartnerExtIDs;
    }

    /**
     * @description Second step of validations. 
     * Checks and updates partner fields if sanity cheсk passed.
     * @param partnerRecords - list of rcords that passed previous validations
     * @return Map<String, String>  Map of external ids of partners with error information.
     */
    public Map<String, String> validatePartnerFields(List<TIP_Wrappers.PartnerData> partnerRecords) {
        Map<String, String> invalidFieldsByExtId = new Map<String, String>();

        //prepare data for validation
        Map<String, Id> ownerIdByEmail = new Map<String, Id>();
        List<User> owners = [
            SELECT Username FROM User 
            WHERE Username IN 
                :TIP_RestValidationProcessor.getCollectedFieldValuesForAll(
                    TIP_Wrappers.Fields_Partner.OWNERID.NAME())
        ];
        for (User aUser : owners) {
            ownerIdByEmail.put(aUser.Username, aUser.Id);
        }

        Map<String, Id> parentAccountsByExtId = new Map<String, Id>();
        List<Account> parentAccounts = [
            SELECT TIP_Account_External_Id__c FROM Account 
            WHERE TIP_Account_External_Id__c IN 
                :TIP_RestValidationProcessor.getCollectedFieldValuesForAll(
                    TIP_Wrappers.Fields_Partner.PARENTACCOUNTEXTERNALID.NAME())
        ];
        for (Account pAccount : parentAccounts) {
            parentAccountsByExtId.put(pAccount.TIP_Account_External_Id__c, pAccount.Id);
        }

        Map<String, String> countryNamesByISOCode = TIP_RestHelperUtil.retrieveIsoCodesMapping();

        for (TIP_Wrappers.PartnerData partnerRecord : partnerRecords) {
            String errMsg = '';
            //check owner Id and replace with SF id in wrapper
            if (!String.isBlank(partnerRecord.ownerId)) {
                Id ownerId = ownerIdByEmail.get(partnerRecord.ownerId);
                if (ownerId == null) {
                    errMsg = String.format(
                        TIP_ValidatorUtil.INVALID_FIELD_VAL, 
                        new List<String>{
                            TIP_Wrappers.Fields_Partner.OWNERID.name(), 
                            partnerRecord.ownerId
                        });
                } else {
                    partnerRecord.ownerId = ownerId;
                }
            }

            //check parent account Id and replace with SF id in wrapper
            if (!String.isBlank(partnerRecord.parentAccountExternalId)) {
                Id parentAccId = parentAccountsByExtId.get(partnerRecord.parentAccountExternalId);
                if (parentAccId == null) {
                    errMsg = String.format(
                        TIP_ValidatorUtil.INVALID_FIELD_VAL, 
                        new List<String>{
                            TIP_Wrappers.Fields_Partner.PARENTACCOUNTEXTERNALID.name(), 
                            partnerRecord.parentAccountExternalId
                        });
                } else {
                    partnerRecord.parentAccountExternalId = parentAccId;
                }
            }

            //check nationality field and replace with proper picklist value
            if (!String.isBlank(partnerRecord.majorCustomerNationality)) {
                String countryName = countryNamesByISOCode.get(partnerRecord.majorCustomerNationality);
                if (String.isBlank(countryName)) {
                    errMsg = String.format(TIP_ValidatorUtil.INVALID_FIELD_VAL, new List<String>{TIP_Wrappers.Fields_Partner.MAJORCUSTOMERNATIONALITY.name(), partnerRecord.majorCustomerNationality});
                } else {
                    partnerRecord.majorCustomerNationality = countryName;
                }
            }

            //other fields - mobile phone, dates, business/partner type - to be validated by SF in DML operation
            
            if (!String.isBlank(errMsg)) {
                invalidFieldsByExtId.put(partnerRecord.externalId, errMsg);
            }
        }
        return invalidFieldsByExtId;
    }

}