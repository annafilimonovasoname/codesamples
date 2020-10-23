/**
 * @author      Anna Filimonova
 * @date        23/03/2020
 * @group       DFS-SFDC
 * @description Working destination records validation
 */
public with sharing class TIP_RestWorkingDestinationValidator {

    /** Static map that collects all valid CMS codes and checks new records against all validated set */
    public static Map<String, String> validCMSCodesToAccId = new Map<String, String>();

    /** List of error messages for the record */
    private List<String> errorMsgs;

    /** Partner record external id */
    private String partnerExtId;
    
    /** Record to validate */
    private TIP_Wrappers.WorkingDestinationData wdRecord;

    /** Record to validate serialized */
    private Map<String, Object> wdRecordTransformed;
    
    /** Validator operator instance that implements different validations based on operation. */
    private TIP_ValidatorUtil validator;

    /** Validator processor instance that processes serialized values. */
    private TIP_RestValidationProcessor val;

    /** Existing record. */
    private TIP_Working_Destination__c wdObject;
    /**
     * @description Creates instance of working destination validator that validates 
     * a set of working destinations that belong to a single partner.
     * @param partnerExternalId partner external id
     * @param wdList list of wrapper records to validate
     * @return Instance of TIP_RestWorkingDestinationValidator.
     */
    public TIP_RestWorkingDestinationValidator(String partnerExternalId, TIP_Wrappers.WorkingDestinationData aRecord, TIP_Working_Destination__c wdObject) {
        this.partnerExtId = partnerExternalId;
        this.wdRecord = aRecord;
        this.wdObject = wdObject;
        String operation = wdObject == null ? CRM_Constants.WEB_SERVICE_ACTION_CREATE : CRM_Constants.WEB_SERVICE_ACTION_UPDATE;

        wdRecordTransformed = TIP_RestHelperUtil.transformJsonToMap(JSON.serialize(wdRecord));
        errorMsgs = new List<String>();
        validator = TIP_ValidatorUtil.getInstance(operation);
        val = new TIP_RestValidationProcessor(partnerExternalId);
    }
    
    /**
     * @description Get all error messages.
     * @param -
     * @return List of logged error messages.
     */
    public List<String> getErrors() {
        return errorMsgs != null ? errorMsgs : new List<String>();
    }

    /**
     * @description Validates fields in destination records against a list of records.
     * @param -
     * @return TRUE if record is valid, FALSE if record is invalid.
     */
    public Boolean isValid() {
        return 
            checkRequiredFields() &&
            checkDuplicateInRecord() &&
            checkFieldFormat() &&
            checkFieldFormatPicklists() &&
            checkDuplicateCMSInRequest() &&
            checkForbiddenFieldsForUpdate();
    }

    /**
     * @description Checks required fields on working destination level.
     * @param -
     * @return TRUE if record is valid (all required fields are populated), 
     *         FALSE if record is invalid (required fields are missing). 
     */
    private Boolean checkRequiredFields() {
        List<String> missingRequiredFields = val.getMissingRequiredFields(
            validator, wdRecordTransformed, 
            TIP_ValidatorUtil.requiredFields_WD, 
            TIP_ValidatorUtil.fieldsToCollect_WD
        );
        if (!missingRequiredFields.isEmpty()) {
            errorMsgs.add(String.format(TIP_ValidatorUtil.REQ_FIELDS_MISSING_WD_ERROR, 
                new List<String>{String.join(missingRequiredFields, ', ')}));
        }
        return missingRequiredFields.isEmpty();
    }

    /**
     * @description Checks for duplicates in working destination data in terms of 1 record.
     * (can't have 2 working destination with the same name).
     * @param -
     * @return TRUE if record is valid (no duplicates), 
     *         FALSE if record is invalid (has duplicates).
     */        
    private Boolean checkDuplicateInRecord() {
        List<String> duplicatedFields = val.getDuplicatedFields(
            wdRecordTransformed, 
            TIP_ValidatorUtil.fieldsToCollect_WD
        );
        if (!duplicatedFields.isEmpty()) {
            errorMsgs.add(String.format(TIP_ValidatorUtil.DUPLICATE_WD_DATA_IN_PARTNER, 
                        new List<String>{String.join(duplicatedFields, ', ')}));
        }
        return duplicatedFields.isEmpty();
    }

    /**
     * @description Checks fields format on working destination level.
     * @param -
     * @return TRUE if record is valid (field format valid), 
     *         FALSE if record is invalid (some fields have invalid format).
     */
    private Boolean checkFieldFormat() {
        Set<String> boolValues = new Set<String>();
        boolValues.add('true');
        boolValues.add('false');

        List<String> invalidFields = new List<String>();
        if (!String.isBlank(wdRecord.cmsCode) && (!wdRecord.cmsCode.isNumeric() || wdRecord.cmsCode.length() != 5)) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.CMSCODE.name());
        }
        if (!String.isBlank(wdRecord.sapPayeeNumber) && (!wdRecord.sapPayeeNumber.isNumeric() || wdRecord.sapPayeeNumber.length() > 9)) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.SAPPAYEENUMBER.name());
        }
        if (!String.isBlank(wdRecord.taxExemption) && !boolValues.contains(wdRecord.taxExemption)) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.TAXEXEMPTION.name());
        }
        if (!String.isBlank(wdRecord.partnerCompliance) && !boolValues.contains(wdRecord.partnerCompliance)) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.PARTNERCOMPLIANCE.name());
        }

        if (!invalidFields.isEmpty()) {
            errorMsgs.add(String.format(TIP_ValidatorUtil.INVALID_FIELDS_FORMAT_WD, new List<String>{wdRecord.Name, String.join(invalidFields, ', ')}));
        }
        return invalidFields.isEmpty(); 
    }

    /**
     * @description Checks restricted picklist values on working destination level.
     * @param -
     * @return TRUE if record is valid (picklist fields contain proper values), 
     *         FALSE if record is invalid (some picklist fields contain improper values).
     */
    private Boolean checkFieldFormatPicklists() {
        List<String> wdOptions = getWDOptions();
        Map<String, List<String>> codeDependentOptions = getCodeDependentOptions();

        List<String> invalidFields = new List<String>();
        if (wdRecord.Name != null && !wdOptions.contains(wdRecord.Name)) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.NAME.name());
            errorMsgs.add(
                String.format(
                    TIP_ValidatorUtil.INVALID_PICKLIST_VALUE, 
                    new List<String>{
                        TIP_Wrappers.Fields_WorkingDestination.NAME.name(), 
                        wdRecord.Name
                    }
                )
            );
        }
        if (wdRecord.Name != null && wdRecord.code != null && 
            codeDependentOptions.get(wdRecord.Name) != null && 
            !codeDependentOptions.get(wdRecord.Name).contains(wdRecord.code)) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.CODE.name());
            errorMsgs.add(
                String.format(
                    TIP_ValidatorUtil.INVALID_DPENDENT_PICKLIST_VALUE,
                    new List<String>{
                        TIP_Wrappers.Fields_WorkingDestination.CODE.name(), 
                        wdRecord.code, 
                        TIP_Wrappers.Fields_WorkingDestination.NAME.name(), 
                        wdRecord.Name
                    }
                ));
        }
        return invalidFields.isEmpty();
    }

    /**
     * @description Checks for duplicates in working destinations from other records.
     * @param -
     * @return TRUE if record is valid (CMS codes are unique or empty), 
     *         FALSE if record is invalid (CMS codes duplicated in request).
     */
    private Boolean checkDuplicateCMSInRequest() {
        String validWDCode = wdRecord.cmsCode;
        if (String.isBlank(validWDCode)) {
            return true;
        }

        if (validCMSCodesToAccId.containsKey(validWDCode)) {
            errorMsgs.add(
                String.format(
                    TIP_ValidatorUtil.DUPLICATE_CMS_IN_REQUEST, 
                    new List<String>{validWDCode}
                )
            );
            return false;
        } /*else {
            validCMSCodesToAccId.put(validWDCode, partnerExtId);
        }*/

        return true;
    }

    /**
     * @description UPDATE only - checks if static fields were updated
     * @param -
     * @return TRUE constant fields were unchanged, FALSE if some of the static fields were updated
     */
    private Boolean checkForbiddenFieldsForUpdate() {
        if (wdObject == null) {
            return true;
        }
        List<String> invalidFields = new List<String>();
        if (wdRecord.cmsCode != null && wdRecord.cmsCode != wdObject.CMS_Code__c) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.CMSCODE.name());
        }
        if (wdRecord.name != null && (wdRecord.name != wdObject.Name || wdRecord.name != wdObject.Working_Destination__c)) {
            invalidFields.add(TIP_Wrappers.Fields_WorkingDestination.Name.name());
        }
        if (!invalidFields.isEmpty()) {
            errorMsgs.add(String.format(
                TIP_ValidatorUtil.FIELD_CANNOT_BE_UPDATED, 
                new List<String>{'Working destination', String.join(invalidFields, ', ')}));
        }
        return invalidFields.isEmpty(); 
    }
    /** Static picklist options to avoid SOQL in loop */

    /** TIP_Working_Destination__c.Working_Destination__c picklist options */    
    private static  List<String> wdOptions;

    /**
     * @description Get method for wdOptions.
     * @param -
     * @return TIP_Working_Destination__c.Working_Destination__c picklist options.
     */
    private static List<String> getWDOptions() {
        if (wdOptions == null) {
            wdOptions = TIP_RestHelperUtil.getPicklistValues(TIP_Working_Destination__c.Working_Destination__c);
        }
        return wdOptions;
    }

    /** TIP_Working_Destination__c.Code__c picklist dependency from TIP_Working_Destination__c.Working_Destination__c */ 
    private static Map<String, List<String>> codeDependentOptions;

    /**
     * @description Get method for codeDependentOptions.
     * @param -
     * @return TIP_Working_Destination__c.Code__c picklist dependency from TIP_Working_Destination__c.Working_Destination__c.
     */
    private static Map<String, List<String>> getCodeDependentOptions() {
        if (codeDependentOptions == null) {
            codeDependentOptions = TIP_RestHelperUtil.getDependentPicklistOptions(
                'TIP_Working_Destination__c', 
                'Working_Destination__c', 
                'Code__c'
            );
        }
        return codeDependentOptions;
    }
}
